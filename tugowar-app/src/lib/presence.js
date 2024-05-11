import { persisted } from 'svelte-persisted-store'

export const presenceStoreKey = "presence";

// First param `preferences` is the local storage key.
// Second param is the initial value.
export const storedPresence = persisted(presenceStoreKey, {
  sessionKeyAddress: undefined,
});
