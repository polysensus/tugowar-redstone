import ds from "downstream";

const counterHQName = "tow_counter_hq_7"
const counterName = "tow_counter";

export default async function update(state) {
    const mobileUnit = getMobileUnit(state);
    const buildings = state.world?.buildings || [];
    const counterHQ = getBuildingsByType(buildings, counterHQName)[0];
    if (!counterHQ)
      console.error(`building ${counterHQName} not found`)
    let score = getDataInt(counterHQ, "score");
    let duration = getDataInt(counterHQ, "duration");
    let gid = getDataInt(counterHQ, "gid");
    let tokenId = getData(counterHQ, "tokenid");
    let complete = getDataInt(counterHQ, "complete");
    let winner = getData(counterHQ, "winner");
    let started = score != 0;

    const bootstrapTokenId = 256;  // polyzone

    if(!tokenId)
      tokenId = bootstrapTokenId;

    const counterBuildings = getBuildingsByType(buildings, counterName);
    const readScore = (tokenId) => {
        const payload = ds.encodeCall("function readScore(uint256)", [tokenId]);
        ds.dispatch({
            name: "BUILDING_USE",
            args: [counterHQ.id, mobileUnit.id, payload],
        });
    };
  
    const revealWinner = (gid) => {
        if (gid == 0) return;
        const payload = ds.encodeCall("function getWinner(uint256)", [gid]);
        ds.dispatch({
            name: "BUILDING_USE",
            args: [counterHQ.id, mobileUnit.id, payload],
        });
    };

    const formUpdate = (values) => {
        console.log(`${JSON.stringify(values)}`);
        let formTokenId = (values["input-tokenid"] || "").toLowerCase();
        let formGameID = (values["input-gameid"] || "").toLowerCase();

        if (formTokenId != "") {
          console.log(`update tokenId ${formTokenId}`);
          tokenId = Number(formTokenId);
        }
        if (formGameID != "") {
          console.log(`update gameid ${formGameID}`);
          gid = Number(formGameID);
        }

        if(tokenId) {
          console.log(`reading score for ${tokenId}`);
          readScore(tokenId);
        }
        if (gid) {
          console.log(`revealing winner for ${gid}`);
          revealWinner(gid);
        }
        console.log(`tokenId: ${tokenId}, gid: ${gid}`);
    }

    const noop = () => {};

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
                        <h3>Tug o' War game ${gid} active token: "${tokenId}"</h3>
                        <p>provide either or both of a game number or a zone number</p>
                        <p><input id="input-tokenid" type="string" name="input-tokenid"></input></p>
                        <p><input id="input-gameid" type="string" name="input-gameid"></input></p>
                        <p>War running for ${duration} blocks</p>
                        <p>Started ${started}</p>
                        <p>Complete ${complete}</p>
                        <p>Winner? ${winner}</p>
                        <p>Brought to you by @fupduk and <a href="https://www.polysensus.com/">Polysensus</a></p>
                        `,
                        submit: (values) => {
                            formUpdate(values);
                        },
                        buttons: [
                            {
                                text: "What's the score ?",
                                type: "action",
                                action: noop,
                            }
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
