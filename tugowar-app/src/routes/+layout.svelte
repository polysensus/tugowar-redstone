<script lang="ts">
  // import process from 'node:process';
	import '../app.pcss';

  // framework imports
  import { page } from '$app/stores';
  import { computePosition, autoUpdate, offset, shift, flip, arrow } from '@floating-ui/dom';
  import { clipboard } from '@skeletonlabs/skeleton';
  import { storePopup } from '@skeletonlabs/skeleton';
  storePopup.set({ computePosition, autoUpdate, offset, shift, flip, arrow });

  import { onMount, setContext } from 'svelte';
  import { get, writable, derived } from 'svelte/store';

  // framework components
	import { AppShell, AppBar } from '@skeletonlabs/skeleton';

  // application components
  import PagePresence from '$lib/components/PagePresence.svelte';

  // application imports
  import { ChainPresence } from '$lib/chains/presence.js';
  import { all } from '$lib/chains/supportedproviders.js';
  // contexts

  /** @type {{request:{href?:string,origin?:string}}} */
  export let data; // see +layout.js:load
  setContext('data', data);

  let arena = writable(undefined);
  setContext('arena', arena);

  const presence = new ChainPresence({ networks: all, hardhatWalletCount: 3 });
  setContext('presence', presence);

  const walletAddress = derived(arena, async ($arena, set) => {
    console.log(`+layout.svelte# walletAddress store: arena changing`);
    if (!$arena) {
      console.log(`+layout.svelte# walletAddress store: arena undefined`);
      set(undefined);
      return;
    }
    const address = await $arena?.signer?.getAddress();
    console.log(`+layout.svelte# walletAddress store: arena ${address}`);
    set(address);
  });
  setContext('walletAddress', walletAddress);

  let walletAddressAbbrev = undefined;

  $: walletAddressAbbrev = abbrevAddr($walletAddress)

  function abbrevAddr(address, sep='..') {
    if (!address) return "";
    return address.slice(0, 6) + sep + address.slice(address.length -2)
  }

  function atRoot(page) {
    let path = page?.url?.pathname;
    if (!path) return false;
    if (path.endsWith('/')) path = path.slice(0, path.length - 1);
    if (path.length !== 0) return false;
    return true;
  }

  // state vars
  let providerButtonText;
  let providerButtonClass = 'btn variant-filled';
  $: providerButtonClass = $arena ? 'btn variant-ringed xl' : 'btn variant-filled xl';

  const polysensusURL = "https://www.polysensus.com";
  const polysensusText = "Polysensus";
  const tugowarText = "Tug Of War";
  let homeRef;
  // $: homeRef = atRoot($page) ? polysensusURL : (new URL("/", $page?.url)).toString();
  let homeText;
  // $: homeText = atRoot($page) ? polysensusText : tugowarText;
  let homeTarget;
  // $: homeTarget = atRoot($page) ? "_blank" : "_self";


  onMount(async () => {
    homeRef = derived(page, ($page) => {
      return atRoot($page) ? polysensusURL : (new URL("/", $page?.url)).toString();
    });

    // homeRef = atRoot($page) ? polysensusURL : (new URL("/", $page?.url)).toString();
    homeText = derived(page, ($page) => atRoot($page) ? polysensusText : tugowarText);
    homeTarget = derived(page, ($page) => atRoot($page) ? "_blank" : "_self");
  })

</script>

<!-- App Shell -->
<AppShell>
	<svelte:fragment slot="header">
		<!-- App Bar -->
		<AppBar>
			<svelte:fragment slot="lead">
        <img src="/apple-icon-120x120-white.png" class="mr-3 h-6 sm:h-9" alt="Polysensus Logo" />
        <span class="self-center whitespace-nowrap text-xl font-semibold dark:text-white"
          >
          {#if (homeRef && homeText && homeTarget)}
          <a href={$homeRef} target={$homeTarget}><strong class="text-xl uppercase">{$homeText}</strong></a>
          {/if}
          </span
        >

			</svelte:fragment>
			<svelte:fragment slot="trail">
        <PagePresence />
        {#if !$walletAddress}
				<a
					class="btn btn-sm variant-ghost-surface"
					href="https://discord.gg/ytn98NnchE"
					target="_blank"
					rel="noreferrer"
				>
					Discord
				</a>
        {:else}
          <p class="invisible w-0" data-clipboard="walletAddress">{$walletAddress}</p>
          <button use:clipboard={{ element: 'walletAddress' }}>{walletAddressAbbrev}</button>
        {/if}
			</svelte:fragment>
		</AppBar>
	</svelte:fragment>
	<!-- Page Route Content -->
	<slot />
</AppShell>