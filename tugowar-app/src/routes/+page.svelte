<script>
	import { updated } from '$app/stores';

  // framework imports
  import { setContext, getContext } from 'svelte';

  // framework components

  // application components

  // application imports

  // -- dungeon creation local state stores

  // --- constants
  
  // contexts
  /**
   * @type {{request:{href?:string,origin?:string}}}
   */
  export let data; // see +page.js:load
  setContext('data', data);

  let arena = getContext('arena');

  let isGameRunning=undefined;
  let currentRopePosition=0;
  let joinedTheLight=false;
  let jointTheDark=false;

  async function update() {
    currentRopePosition = await arena.getCurrentRopePosition();
    isGameRunning = await arena.isGameRunning();
  }

</script>
  <div class="h-56 grid content-center">
  <h2 class="h2 flex justify-center">Tug of War: Redstone Composability Hack</h2>
  <h2 class="h3 flex justify-center">(Attack of the Sybils)</h2>
  <div class="flex justify-center gap-4">
    <button type="button" class="btn btn-sm preset-filled">Small</button>
    <button type="button" class="btn btn-sm preset-filled">Large</button>
  </div>
  <div class="flex justify-center">
  <button class="btn btn-sm preset-filled" on:click={async () => await update()}>Update</button>
  </div>
  <div class="flex justify-center">
  <ul class="list">
    <li>
      <span class="flex-auto">Game in progress</span>
      <span class="badge variant-filled">{isGameRunning ? "no" : "yes"}</span>
    </li>
    <li>
      <span class="flex-auto">Rope Position</span>
      <span class="badge variant-filled">{currentRopePosition}</span>
    </li>
    <!-- ... -->
  </ul>
  </div>

  </div>
  <!--
  <a href="/trial/create" class="btn variant-ringed-surface">Narrate</a>
  <a href="/trial/lobby" class="btn variant-ringed-surface">Raid</a>
  -->
<style>
  /* You can still add styles here using element selectors */
  body, html {
    height: 100%;
    margin: 0;
  }
  .container {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh; /* Full height of the viewport */
  }
</style>
