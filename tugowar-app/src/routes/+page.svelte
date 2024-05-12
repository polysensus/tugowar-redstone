<script lang="ts">
  import {ethers} from 'ethers';
	// import {updated} from '$app/stores';
  import accountSol from "$lib/abi/ERC6551Account.json";
  //import registrySol from "$lib/abi/IERC6551Registry.json";
  import tugawarSol from "$lib/abi/TugAWar.json";

  // framework imports
  import { setContext, getContext } from 'svelte';
  import { readable, writable, derived } from 'svelte/store';
  import { clipboard } from '@skeletonlabs/skeleton';

  // framework components

  // application components

  // application imports

  // -- dungeon creation local state stores

  // --- constants
  const abiCoder = ethers.utils.defaultAbiCoder;
  const pollInterval = 1000 * 4;

  // contexts
  /**
   * @type {{request:{href?:string,origin?:string}}}
   */
  export let data; // see +page.js:load
  setContext('data', data);
  let presence = getContext('presence');

  let arena = getContext('arena');

  // we only have this on the browser
  // if this is defined, its the active state for the currenly selected token
  const active = writable(undefined, (set) => {

    getActiveGame()
      .then((result) => {
        set(result);
      });

	  const interval = setInterval(async () => {
	  	set(await getActiveGame());
	  }, pollInterval);

	  return () => clearInterval(interval);
  });
  // let active;
  $: gid = $active?.gid;
  $: duration = $active?.duration;
  $: pulls = $active?.pulls;
  $: marker = $active?.marker;
  $: tokenId = $active?.tokenId;
  $: isGameRunning = typeof marker !== 'undefined' && marker > 5 && marker < 15;
  $: boundAddr = $boundToken?.bound;


  let boundToken = writable();
  async function refreshBoundAccount(tokenId) {
    if (!tokenId) return;

    const chain = presence?.providerSwitch?.current;
    if (!chain) return;
    console.log(`/api/tokenaccount?chain=${chain}&tokenid=${tokenId}`);
    const resp = await fetch(`/api/tokenaccount/?chain=${chain}&tokenid=${tokenId}`);
    const binding = await resp.json();
    console.log(JSON.stringify(binding));
    $boundToken = binding;
  }

  const boundAccount = derived([arena, boundToken], async ([$arena, $boundToken], set) => {
    const signer = await $arena?.signer;
    if (!signer || !$boundToken) {
        set(undefined);
        return;
    }
    try {
      set(new ethers.Contract($boundToken.bound, accountSol.abi, signer));
    } catch (err) {
      console.log(`error creating account contract: ${$boundToken.bound} ${signer}`)
    }
  });

  async function getActiveGame() {
    const tugawarAddr = $arena?.address;
    const provider = presence?.providerSwitch?.getCurrent()?.provider;
    const bound = $boundToken?.bound;

    if (!$boundAccount || !tugawarAddr || !provider ||!bound) {
      console.log("account not bound or game or provider ${provider} not available");
      return;
    }
    console.log('updating active..');

    const tugawar = new ethers.Contract(tugawarAddr, tugawarSol.abi, provider);
    let result = await tugawar.getGameByAccount(bound);
    console.log(`tugawar: ${tugawarAddr}, bound ${bound} result: ${JSON.stringify(result)}`);
    const [gid, duration, pulls, side, tokenId, marker] = result;
    // result = await tugawar['getGame(uint256)'](0);
    // console.log(`getGame result: ${JSON.stringify(result)}`);

    return {gid, duration, pulls, side, tokenId, marker};
  }

  async function pullRope() {
    // throw new Error('deploy the contracts with the new Pull method');
    // use the interace to abi encode the call data
    //
    if (!$arena?.address) {
      console.log(`tugowar signer not ready`);
      return;
    }
    // We just need the address here, just getting it from the same place we get
    // the signer address for consistency
    const tugawarAddr = $arena?.address;
    if (!tugawarAddr) {
      console.log(`tugawar signer not availble`);
      return;
    }

    const tugawarIface = new ethers.utils.Interface(tugawarSol.abi);
    const encodedCall = tugawarIface.encodeFunctionData("Pull");
    let result;
    try {
      result = await $boundAccount.execute(tugawarAddr, 0, encodedCall, 0);
    } catch (err) {
      console.log(`Pull error: ${err}`);
      return;
    }
    console.log("result: ${JSON.stringify(result)}");
    $active = await getActiveGame();
    return result;
}

async function joinSide(side) {
  let sideId;
  if (side === 1 || typeof side === 'string' && side.toLowerCase() === 'light')
    sideId = 1;
  if (side === 2 || typeof side === 'string' && side.toLowerCase() === 'dark')
    sideId = 2;
  if (typeof sideId === 'undefined')
    sideId = 0; // pick the first free side no matter what

  if (!$arena?.address)
    throw new Error(`tugowar signer not ready`);
  // We just need the address here, just getting it from the same place we get
  // the signer address for consistency
  const tugawarAddr = $arena?.address;
  if (!tugawarAddr) throw new Error(`tugawar signer not availble`);

  const tugawarIface = new ethers.utils.Interface(tugawarSol.abi);
  const encodedCall = tugawarIface.encodeFunctionData("joinSide", [sideId]);
  let result;
  try {
    console.log(`boundAccount: ${$boundAccount} ${$boundAccount?.address}`)
    result = await $boundAccount.execute(tugawarAddr, 0, encodedCall, 0);
  } catch (err) {
    console.log(`joinSide($sideId) error: ${err}`);
    return;
  }
  $active = await getActiveGame();
  return result;
}

// for the public view methods, we can just use tugawar directly


</script>
  <div class="h-56 grid content-center">
  <h2 class="h2 flex justify-center">Tug of War: Redstone Composability Hack</h2>
  <h2 class="h3 flex justify-center">(Attack of the Sybils)</h2>
  <div class="flex justify-center gap-4">
    <div class="card">
	    <!-- <header class="card-header">(header)</header> -->
	    <section class="p-4"><input class="input" title="tokenId" type="number" on:input={(e) => refreshBoundAccount(e.target.value)}/></section>
      {#if $boundToken?.bound}
	    <footer class="card-footer">
      <p class="invisible w-0" data-clipboard="boundAddress">{boundAddr}</p>
      <button use:clipboard={{ element: 'boundAddress' }}>{boundAddr}</button>
      </footer>
      {/if}
    </div>
    {#if (gid)}
    <div class="card">
	    <section class="p-4">
      <div class="flex justify-center">
      <ul class="list">
        <li>
          <span class="flex-auto">Game</span>
          <span class="badge variant-filled">{gid}</span>
        </li>
        <li>
          <span class="flex-auto">Marker</span>
          <span class="badge variant-filled">{marker}</span>
        </li>
        <li>
          <span class="flex-auto">Pulls</span>
          <span class="badge variant-filled">{pulls}</span>
        </li>
      </ul>
      </div>
      </section>
    </div>
    {/if}

  </div>

  {#if (tokenId != $boundToken?.tokenId && !isGameRunning)}
  <div class="flex justify-center">
  <button class="btn btn-sm preset-filled" on:click={async () => await joinSide()}>Join Any Side</button>
  </div>
  {:else if isGameRunning}
  <div class="flex justify-center">
  <button class="btn btn-sm preset-filled" on:click={async () => await pullRope()}>Pull!</button>
  </div>

  {/if}
  <div class="flex justify-center">
  <ul class="list">
    {#if !tokenId}
    <li>
      <span class="flex-auto">Enter a zone number or token id in the box above</span>
    </li>

    {:else}
    <li>
      <span class="flex-auto">Game in progress</span>
      <span class="badge variant-filled">{isGameRunning ? "yes" : "no"}</span>
    </li>
    <li>
      <span class="flex-auto">Rope Position</span>
      <span class="badge variant-filled">{marker}</span>
    </li>
    {/if}
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
