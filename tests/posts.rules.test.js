/**
 * Firestore Security Rules — /posts collection
 *
 * Run with the Firestore emulator active:
 *   firebase emulators:start --only firestore
 *   npm test
 *
 * Or in one shot:
 *   firebase emulators:exec --only firestore "npm test"
 */

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

// ─── Constants ───────────────────────────────────────────────────────────────

const OWNER_UID = 'uid-owner-001';
const OTHER_UID = 'uid-other-002';

/** A document that passes every rule in isValidPost(). */
const VALID_POST = {
  title: 'Phòng trọ đẹp gần trường',
  location: '123 Đường Nguyễn Văn Linh, P. Tân Thuận Đông',
  province: 'Thành phố Hồ Chí Minh',
  district: 'Quận 7',
  roomType: 'Phòng trọ',
  amenities: ['Có máy lạnh', 'Có chỗ để xe'],
  lifestyleHabits: ['Không hút thuốc'],
  price: 3000000,
  area: 25,
  capacity: 2,
  description: 'Phòng sạch sẽ, thoáng mát, an ninh tốt.',
  imageUrl: 'https://res.cloudinary.com/example/image/upload/v1/room.jpg',
  imageUrls: ['https://res.cloudinary.com/example/image/upload/v1/room.jpg'],
  ownerId: OWNER_UID,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const ALL_ROOM_TYPES = [
  'Phòng trọ',
  'Phòng trong nhà nguyên căn',
  'Căn hộ / Chung cư',
  'Phòng master',
  'Phòng thường',
  'Phòng có gác',
  'Phòng không gác',
  'Phòng có nội thất',
  'Phòng không nội thất',
  'Studio (Phòng có nội thất)',
  'Duplex (Phòng có gác và nội thất)',
];

// ─── Test environment setup ───────────────────────────────────────────────────

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'roommateapp-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

const ownerDb  = () => testEnv.authenticatedContext(OWNER_UID).firestore();
const otherDb  = () => testEnv.authenticatedContext(OTHER_UID).firestore();
const anonDb   = () => testEnv.unauthenticatedContext().firestore();
const postsCol = (db) => db.collection('posts');
const postDoc  = (db, id = 'post1') => db.collection('posts').doc(id);

/** Write a post bypassing rules (used for update/delete test setup). */
async function seedPost(id = 'post1', overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore()
      .collection('posts')
      .doc(id)
      .set({ ...VALID_POST, ownerId: OWNER_UID, ...overrides });
  });
}

// ─── READ ─────────────────────────────────────────────────────────────────────

describe('read', () => {
  beforeEach(() => seedPost());

  it('allows any authenticated user to read a post', async () => {
    await assertSucceeds(postDoc(ownerDb()).get());
    await assertSucceeds(postDoc(otherDb()).get());
  });

  it('denies unauthenticated read', async () => {
    await assertFails(postDoc(anonDb()).get());
  });
});

// ─── CREATE ───────────────────────────────────────────────────────────────────

describe('create', () => {
  it('allows an authenticated user to create a valid post', async () => {
    await assertSucceeds(postsCol(ownerDb()).add(VALID_POST));
  });

  it('denies unauthenticated create', async () => {
    await assertFails(postsCol(anonDb()).add(VALID_POST));
  });

  // ── ownerId ──────────────────────────────────────────────────────────────

  it('denies when ownerId does not match auth.uid', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, ownerId: OTHER_UID }),
    );
  });

  // ── required fields ───────────────────────────────────────────────────────

  it('denies a document missing the title field', async () => {
    const { title, ...withoutTitle } = VALID_POST;
    await assertFails(postsCol(ownerDb()).add(withoutTitle));
  });

  it('denies a document missing imageUrls', async () => {
    const { imageUrls, ...withoutImageUrls } = VALID_POST;
    await assertFails(postsCol(ownerDb()).add(withoutImageUrls));
  });

  it('denies a document missing createdAt', async () => {
    const { createdAt, ...withoutCreatedAt } = VALID_POST;
    await assertFails(postsCol(ownerDb()).add(withoutCreatedAt));
  });

  // ── title ─────────────────────────────────────────────────────────────────

  it('denies an empty title', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, title: '' }));
  });

  it('denies a title longer than 200 characters', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, title: 'a'.repeat(201) }),
    );
  });

  it('allows a title of exactly 200 characters', async () => {
    await assertSucceeds(
      postsCol(ownerDb()).add({ ...VALID_POST, title: 'a'.repeat(200) }),
    );
  });

  // ── location / province / description ─────────────────────────────────────

  it('denies an empty location', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, location: '' }));
  });

  it('denies an empty province', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, province: '' }));
  });

  it('denies an empty description', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, description: '' }),
    );
  });

  it('denies a description longer than 5000 characters', async () => {
    await assertFails(
      postsCol(ownerDb()).add({
        ...VALID_POST,
        description: 'x'.repeat(5001),
      }),
    );
  });

  // ── district (optional) ───────────────────────────────────────────────────

  it('allows an empty district', async () => {
    await assertSucceeds(
      postsCol(ownerDb()).add({ ...VALID_POST, district: '' }),
    );
  });

  // ── roomType whitelist ────────────────────────────────────────────────────

  it('allows every valid roomType value', async () => {
    for (const roomType of ALL_ROOM_TYPES) {
      await assertSucceeds(
        postsCol(ownerDb()).add({ ...VALID_POST, roomType }),
      );
    }
  });

  it('denies an unrecognised roomType', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, roomType: 'Lều bạt' }),
    );
  });

  it('denies an empty roomType', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, roomType: '' }),
    );
  });

  // ── price ─────────────────────────────────────────────────────────────────

  it('denies price = 0', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, price: 0 }));
  });

  it('denies negative price', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, price: -500 }));
  });

  it('denies price > 1,000,000,000', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, price: 1_000_000_001 }),
    );
  });

  it('allows price = 1,000,000,000 (upper boundary)', async () => {
    await assertSucceeds(
      postsCol(ownerDb()).add({ ...VALID_POST, price: 1_000_000_000 }),
    );
  });

  // ── area ─────────────────────────────────────────────────────────────────

  it('denies area = 0', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, area: 0 }));
  });

  it('denies area > 10,000', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, area: 10_001 }),
    );
  });

  // ── capacity ─────────────────────────────────────────────────────────────

  it('denies capacity = 0', async () => {
    await assertFails(postsCol(ownerDb()).add({ ...VALID_POST, capacity: 0 }));
  });

  it('denies capacity > 100', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, capacity: 101 }),
    );
  });

  // ── imageUrls ─────────────────────────────────────────────────────────────

  it('denies an empty imageUrls list', async () => {
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, imageUrls: [] }),
    );
  });

  it('denies imageUrls with more than 5 items', async () => {
    const urls = Array.from({ length: 6 }, (_, i) =>
      `https://example.com/img${i}.jpg`,
    );
    await assertFails(
      postsCol(ownerDb()).add({ ...VALID_POST, imageUrls: urls }),
    );
  });

  it('allows imageUrls with exactly 5 items', async () => {
    const urls = Array.from({ length: 5 }, (_, i) =>
      `https://example.com/img${i}.jpg`,
    );
    await assertSucceeds(
      postsCol(ownerDb()).add({
        ...VALID_POST,
        imageUrls: urls,
        imageUrl: urls[0],
      }),
    );
  });

  // ── lists ─────────────────────────────────────────────────────────────────

  it('allows empty amenities list', async () => {
    await assertSucceeds(
      postsCol(ownerDb()).add({ ...VALID_POST, amenities: [] }),
    );
  });

  it('denies amenities list with more than 20 items', async () => {
    await assertFails(
      postsCol(ownerDb()).add({
        ...VALID_POST,
        amenities: Array.from({ length: 21 }, (_, i) => `amenity-${i}`),
      }),
    );
  });
});

// ─── UPDATE ───────────────────────────────────────────────────────────────────

describe('update', () => {
  beforeEach(() => seedPost());

  it('allows the owner to update mutable fields', async () => {
    await assertSucceeds(
      postDoc(ownerDb()).update({
        title: 'Tiêu đề đã chỉnh sửa',
        price: 3500000,
        updatedAt: new Date(),
      }),
    );
  });

  it('denies update by a non-owner', async () => {
    await assertFails(
      postDoc(otherDb()).update({ title: 'Hack title', updatedAt: new Date() }),
    );
  });

  it('denies unauthenticated update', async () => {
    await assertFails(
      postDoc(anonDb()).update({ title: 'Hack title', updatedAt: new Date() }),
    );
  });

  it('denies changing ownerId', async () => {
    await assertFails(
      postDoc(ownerDb()).update({ ownerId: OTHER_UID, updatedAt: new Date() }),
    );
  });

  it('denies changing createdAt', async () => {
    await assertFails(
      postDoc(ownerDb()).update({ createdAt: new Date(), updatedAt: new Date() }),
    );
  });

  it('denies setting title to empty string on update', async () => {
    await assertFails(
      postDoc(ownerDb()).update({ title: '', updatedAt: new Date() }),
    );
  });

  it('denies setting price to 0 on update', async () => {
    await assertFails(
      postDoc(ownerDb()).update({ price: 0, updatedAt: new Date() }),
    );
  });

  it('denies setting an invalid roomType on update', async () => {
    await assertFails(
      postDoc(ownerDb()).update({
        roomType: 'Loại không hợp lệ',
        updatedAt: new Date(),
      }),
    );
  });

  it('denies setting empty imageUrls on update', async () => {
    await assertFails(
      postDoc(ownerDb()).update({ imageUrls: [], updatedAt: new Date() }),
    );
  });
});

// ─── DELETE ───────────────────────────────────────────────────────────────────

describe('delete', () => {
  beforeEach(() => seedPost());

  it('allows the owner to delete their post', async () => {
    await assertSucceeds(postDoc(ownerDb()).delete());
  });

  it('denies delete by a non-owner', async () => {
    await assertFails(postDoc(otherDb()).delete());
  });

  it('denies unauthenticated delete', async () => {
    await assertFails(postDoc(anonDb()).delete());
  });
});
