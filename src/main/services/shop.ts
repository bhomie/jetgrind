import { getPrisma } from './storage';

export async function getShopItems() {
  const prisma = getPrisma();
  return await prisma.shopItem.findMany({
    orderBy: [
      { isPremium: 'asc' },
      { requiredLevel: 'asc' },
      { price: 'asc' },
    ],
  });
}

export async function purchaseItem(itemId: string) {
  const prisma = getPrisma();

  const user = await prisma.user.findFirst();
  if (!user) {
    return { success: false, error: 'User not found' };
  }

  const item = await prisma.shopItem.findUnique({
    where: { id: itemId },
  });

  if (!item) {
    return { success: false, error: 'Item not found' };
  }

  // Check if already owned
  const existingItem = await prisma.inventoryItem.findUnique({
    where: {
      userId_shopItemId: {
        userId: user.id,
        shopItemId: itemId,
      },
    },
  });

  if (existingItem) {
    return { success: false, error: 'Item already owned' };
  }

  // Check level requirement
  if (user.level < item.requiredLevel) {
    return { success: false, error: `Requires level ${item.requiredLevel}` };
  }

  // Check coins
  if (user.coins < item.price) {
    return { success: false, error: 'Not enough coins' };
  }

  // Purchase
  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      data: {
        coins: user.coins - item.price,
      },
    }),
    prisma.inventoryItem.create({
      data: {
        userId: user.id,
        shopItemId: itemId,
      },
    }),
  ]);

  return { success: true };
}

export async function getInventory() {
  const prisma = getPrisma();
  const user = await prisma.user.findFirst();
  if (!user) return [];

  const inventory = await prisma.inventoryItem.findMany({
    where: { userId: user.id },
    include: {
      shopItem: true,
    },
  });

  const equipped = await prisma.equippedCosmetic.findMany({
    where: { userId: user.id },
  });

  const equippedItemIds = new Set(equipped.map((e) => e.shopItemId));

  return inventory.map((item) => ({
    ...item,
    isEquipped: equippedItemIds.has(item.shopItemId),
  }));
}

export async function equipItem(itemId: string) {
  const prisma = getPrisma();
  const user = await prisma.user.findFirst();
  if (!user) {
    return { success: false, error: 'User not found' };
  }

  // Verify ownership
  const inventoryItem = await prisma.inventoryItem.findUnique({
    where: {
      userId_shopItemId: {
        userId: user.id,
        shopItemId: itemId,
      },
    },
    include: {
      shopItem: true,
    },
  });

  if (!inventoryItem) {
    return { success: false, error: 'Item not owned' };
  }

  const slot = inventoryItem.shopItem.type;

  // Upsert equipped item (replace existing in same slot)
  await prisma.equippedCosmetic.upsert({
    where: {
      userId_slot: {
        userId: user.id,
        slot,
      },
    },
    update: {
      shopItemId: itemId,
      equippedAt: new Date(),
    },
    create: {
      userId: user.id,
      shopItemId: itemId,
      slot,
    },
  });

  return { success: true };
}

export async function unequipItem(slot: string) {
  const prisma = getPrisma();
  const user = await prisma.user.findFirst();
  if (!user) {
    return { success: false, error: 'User not found' };
  }

  await prisma.equippedCosmetic.deleteMany({
    where: {
      userId: user.id,
      slot,
    },
  });

  return { success: true };
}

export async function seedShopItems() {
  const prisma = getPrisma();

  const existingCount = await prisma.shopItem.count();
  if (existingCount > 0) return;

  const items = [
    // Hats
    { name: 'Cat Ears', description: 'Adorable cat ears for your pet!', type: 'hat', rarity: 'common', price: 50, isPremium: false, requiredLevel: 1, imageUrl: '/assets/cosmetics/cat-ears.png' },
    { name: 'Crown', description: 'A royal crown fit for a king or queen.', type: 'hat', rarity: 'rare', price: 200, isPremium: false, requiredLevel: 10, imageUrl: '/assets/cosmetics/crown.png' },
    { name: 'Wizard Hat', description: 'Magical wizard hat with stars.', type: 'hat', rarity: 'epic', price: 500, isPremium: true, requiredLevel: 20, imageUrl: '/assets/cosmetics/wizard-hat.png' },

    // Accessories
    { name: 'Bow Tie', description: 'A cute pink bow tie.', type: 'accessory', rarity: 'common', price: 30, isPremium: false, requiredLevel: 1, imageUrl: '/assets/cosmetics/bow-tie.png' },
    { name: 'Star Wand', description: 'A sparkly star wand.', type: 'accessory', rarity: 'uncommon', price: 100, isPremium: false, requiredLevel: 5, imageUrl: '/assets/cosmetics/star-wand.png' },
    { name: 'Angel Wings', description: 'Beautiful angel wings.', type: 'accessory', rarity: 'legendary', price: 1000, isPremium: true, requiredLevel: 50, imageUrl: '/assets/cosmetics/angel-wings.png' },

    // Backgrounds
    { name: 'Starry Night', description: 'A beautiful starry background.', type: 'background', rarity: 'common', price: 40, isPremium: false, requiredLevel: 1, imageUrl: '/assets/cosmetics/starry-night.png' },
    { name: 'Cherry Blossoms', description: 'Peaceful cherry blossom scene.', type: 'background', rarity: 'uncommon', price: 80, isPremium: false, requiredLevel: 3, imageUrl: '/assets/cosmetics/cherry-blossoms.png' },
    { name: 'Rainbow World', description: 'A vibrant rainbow paradise.', type: 'background', rarity: 'rare', price: 300, isPremium: true, requiredLevel: 15, imageUrl: '/assets/cosmetics/rainbow-world.png' },

    // Outfits
    { name: 'Sailor Uniform', description: 'Classic sailor uniform.', type: 'outfit', rarity: 'uncommon', price: 150, isPremium: false, requiredLevel: 5, imageUrl: '/assets/cosmetics/sailor-uniform.png' },
    { name: 'Princess Dress', description: 'Elegant princess dress.', type: 'outfit', rarity: 'epic', price: 600, isPremium: true, requiredLevel: 25, imageUrl: '/assets/cosmetics/princess-dress.png' },
  ];

  await prisma.shopItem.createMany({ data: items });
}
