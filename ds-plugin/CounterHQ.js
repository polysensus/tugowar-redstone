import ds from "downstream";

const counterHQName = "tow_counter_hq"

export default async function update(state) {
    const mobileUnit = getMobileUnit(state);
    const buildings = state.world?.buildings || [];
    const counterHQ = getBuildingsByType(buildings, counterHQName)[0];
    if (!counterHQ)
      console.error(`building ${counterHQName} not found`)
    const score = getDataInt(counterHQ, "score");
    const duration = getDataInt(counterHQ, "duration");
    const gid = getDataInt(counterHQ, "gid");
    const tokenId = getData(counterHQ, "tokenid");
    const complete = getDataInt(counterHQ, "complete");
    const winner = getData(counterHQ, "winner");
    const started = score != 0;

    const bootstrapTokenId = 256;  // polyzone

    const counterBuildings = getBuildingsByType(buildings, "counter");

    const readScore = () => {
        const payload = ds.encodeCall("function readScore(uint256)", [bootstrapTokenId]);
        ds.dispatch({
            name: "BUILDING_USE",
            args: [counterHQ.id, mobileUnit.id, payload],
        });
    };

    const revealWinner = () => {
        if (gid == 0) return;
        const payload = ds.encodeCall("function getWinner(uint256)", [gid]);
        ds.dispatch({
            name: "BUILDING_USE",
            args: [counterHQ.id, mobileUnit.id, payload],
        });
    };

    return {
        version: 1,
        map: counterBuildings.map((b) => ({
            type: "building",
            id: `${b.id}`,
            key: "labelText",
            value: `${score}`,
        })),
        components: [
            {
                id: "counter-hq",
                type: "building",
                content: [
                    {
                        id: "default",
                        type: "inline",
                        html: `
                        <h3>Tug o' War gid:${gid} token: ${tokenId}</h3>
                        <p>War running for ${duration} blocks</p>
                        <p>Started ${started}</p>
                        <p>Complete ${complete}</p>
                        <p>Winner? ${winner}</p>
                        <p>Brought to you by @fupduk and <a href="https://www.polysensus.com/">Polysensus</a></p>
                        `,

                        buttons: [
                            {
                                text: "What's the Score?!",
                                type: "action",
                                action: readScore,
                            },
                            {
                              /*  todo: disable this once joined and while games
                               *  in progress */
                                text: "Reveal Winner (if complete)",
                                type: "action",
                                action: revealWinner,
                            },
                        ],
                    },
                ],
            },
        ],
    };
}

function getMobileUnit(state) {
    return state?.selected?.mobileUnit;
}

const getBuildingsByType = (buildingsArray, type) => {
    return buildingsArray.filter(
        (building) =>
            building.kind?.name?.value.toLowerCase().trim() ==
            type.toLowerCase().trim(),
    );
};

// -- Onchain data helpers --

function getDataInt(buildingInstance, key) {
    var hexVal = getData(buildingInstance, key);
    return typeof hexVal === "string" ? parseInt(hexVal, 16) : 0;
}

function getData(buildingInstance, key) {
    return getKVPs(buildingInstance)[key];
}

function getKVPs(buildingInstance) {
    return (buildingInstance.allData || []).reduce((kvps, data) => {
        kvps[data.name] = data.value;
        return kvps;
    }, {});
}
