<script lang="ts">

  import { onMount, getContext } from 'svelte';
  import { page } from '$app/stores';
  import ProvidersList from '$lib/components/ProvidersList.svelte';
  import { namedProviderRoute } from '$lib/chains/supportedproviders.js';
	import { ethers } from 'ethers';

  import tugawarSol from "$lib/abi/TugAWar.json";
  let providers;
  let selected;
  let lastID = undefined;

  const data = getContext('data');
  const presence = getContext('presence');
  const arena = getContext('arena');

  async function providerSelected(event) {
    console.log(`PagePresence# ${event?.detail?.id} event.detail ${JSON.stringify(event)}`);

    if (!event.detail || event.detail.id === lastID) {
      console.log(`PagePresence# logout ${lastID}`);
      presence.logout();
      lastID = undefined;
      await arena.set(undefined);
      selected = undefined;
      return;
    }

    await presence.selectProvider(event.detail.id);
    selected = await connectCurrent();
    console.log(`PagePresence# selected ${selected?.id}`);
  }

  async function connectCurrent() {

    const current = presence?.providerSwitch?.getCurrent()
    if (!current?.signer) {
      console.log(`PagePresence# no current signer, not connected`);
      return;
    }

    const address = data.arenaAddress[current.cfg.name];
    if (!address) {
      console.log(`PagePresence# no address for provider config: ${current.cfg.id} ${JSON.stringify(data.arenaAddress)}`);
      return;
    }
    // arena.set(arenaConnect(address, current.signer));
    arena.set(new ethers.Contract(address, tugawarSol.abi, current.signer));
    lastID = current.cfg.id;
    console.log(`PagePresence# current ${lastID} @${address}`);
    return current.cfg;
  }

  async function refreshConnectedProvider() {
    if (!presence?.providerSwitch) return;
    console.log(`PagePresence# refreshing login status`);
    const connectedName = await presence.providerSwitch.refreshLoginStatus(true);
    const routedID = namedProviderRoute($page);
    if (!(connectedName || routedID)) return;

    // The web3auth provider remains connected until explicitly logged out. But
    // we want to prefer the routed provider for the presence selection
    let routedProvider, connectedProvider;
    for (const p of providers) {
      if (routedID && !routedProvider && p.id === routedID) routedProvider = p;
      if (!connectedProvider && p.id === connectedName) connectedProvider = p;
      if (connectedProvider && (!routedID || routedProvider)) break;
    }
    return routedProvider ?? connectedProvider;
  }

  onMount(async () => {
    providers = Object.values(await presence.refreshProviders());

    // Note: we have to do this because we are using web3auth in re-direct mode
    // (for maximum mobile compat). which means we lose state when we redirect &
    // callback
    await refreshConnectedProvider()
    selected = await connectCurrent();
  });
</script>
<ProvidersList on:providerSelected={providerSelected} {providers} bind:selected={selected}>

</ProvidersList>

