/* This file is part of the ScriptDev2 Project. See AUTHORS file for Copyright information
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/* ScriptData
SDName: npc_capital_teleporter
SD%Complete: 100
SDComment: Custom NPC that offers free teleportation between same-faction capital cities.
SDCategory: Custom
EndScriptData */

/* ContentData
npc_capital_teleporter
EndContentData */

#include "AI/ScriptDevAI/include/sc_common.h"

enum CapitalZoneId
{
    ZONE_STORMWIND      = 1519,
    ZONE_IRONFORGE      = 1537,
    ZONE_DARNASSUS      = 1657,
    ZONE_EXODAR         = 3557,
    ZONE_ORGRIMMAR      = 1637,
    ZONE_THUNDER_BLUFF  = 1638,
    ZONE_UNDERCITY      = 1497,
    ZONE_SILVERMOON     = 3487,
};

// Actions are assigned as sequential offsets from GOSSIP_ACTION_INFO_DEF.
// Alliance: +1..+4, Horde: +5..+8, so both sets fit without overlap.
enum CapitalTeleporterAction
{
    ACTION_STORMWIND        = GOSSIP_ACTION_INFO_DEF + 1,
    ACTION_IRONFORGE        = GOSSIP_ACTION_INFO_DEF + 2,
    ACTION_DARNASSUS        = GOSSIP_ACTION_INFO_DEF + 3,
    ACTION_EXODAR           = GOSSIP_ACTION_INFO_DEF + 4,
    ACTION_ORGRIMMAR        = GOSSIP_ACTION_INFO_DEF + 5,
    ACTION_THUNDER_BLUFF    = GOSSIP_ACTION_INFO_DEF + 6,
    ACTION_UNDERCITY        = GOSSIP_ACTION_INFO_DEF + 7,
    ACTION_SILVERMOON       = GOSSIP_ACTION_INFO_DEF + 8,
};

// npc_text ID inserted by npc_capital_teleporter.sql
static const uint32 GOSSIP_TEXT_TELEPORTER = 190001;

struct CapitalDest
{
    uint32 zoneId;
    uint32 mapId;
    float x, y, z, o;
    uint32 action;
    const char* name;
};

static const CapitalDest ALLIANCE_DESTS[] =
{
    { ZONE_STORMWIND,     0,   -8825.0f,   626.0f,   94.0f, 3.14f, ACTION_STORMWIND,     "Stormwind City" },
    { ZONE_IRONFORGE,     0,   -4841.0f, -1045.0f,  502.0f, 1.15f, ACTION_IRONFORGE,     "Ironforge"      },
    { ZONE_DARNASSUS,     1,    9951.6f,  2280.9f, 1341.4f, 1.49f, ACTION_DARNASSUS,     "Darnassus"      },
    { ZONE_EXODAR,        530, -3961.6f,-11653.6f, -137.7f, 1.02f, ACTION_EXODAR,        "The Exodar"     },
};

static const CapitalDest HORDE_DESTS[] =
{
    { ZONE_ORGRIMMAR,     1,    1669.0f, -4339.0f,   62.0f, 3.14f, ACTION_ORGRIMMAR,     "Orgrimmar"      },
    { ZONE_THUNDER_BLUFF, 1,   -1270.0f,    72.0f,  128.5f, 0.77f, ACTION_THUNDER_BLUFF, "Thunder Bluff"  },
    { ZONE_UNDERCITY,     0,    1574.0f,   239.0f,  -52.0f, 3.14f, ACTION_UNDERCITY,     "Undercity"      },
    { ZONE_SILVERMOON,    530,  9484.0f, -7484.0f,   14.0f, 3.14f, ACTION_SILVERMOON,    "Silvermoon City"},
};

static const int CAPITAL_COUNT = 4;

bool GossipHello_npc_capital_teleporter(Player* pPlayer, Creature* pCreature)
{
    uint32 currentZone = pCreature->GetZoneId();

    const CapitalDest* dests = pPlayer->GetTeam() == ALLIANCE ? ALLIANCE_DESTS : HORDE_DESTS;

    for (int i = 0; i < CAPITAL_COUNT; ++i)
    {
        if (dests[i].zoneId != currentZone)
            pPlayer->ADD_GOSSIP_ITEM(GOSSIP_ICON_TAXI, dests[i].name, GOSSIP_SENDER_MAIN, dests[i].action);
    }

    pPlayer->SEND_GOSSIP_MENU(GOSSIP_TEXT_TELEPORTER, pCreature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_capital_teleporter(Player* pPlayer, Creature* /*pCreature*/, uint32 /*uiSender*/, uint32 action)
{
    const CapitalDest* dests = pPlayer->GetTeam() == ALLIANCE ? ALLIANCE_DESTS : HORDE_DESTS;

    for (int i = 0; i < CAPITAL_COUNT; ++i)
    {
        if (dests[i].action == action)
        {
            pPlayer->CLOSE_GOSSIP_MENU();
            pPlayer->TeleportTo(dests[i].mapId, dests[i].x, dests[i].y, dests[i].z, dests[i].o);
            return true;
        }
    }

    return true;
}

void AddSC_npc_capital_teleporter()
{
    Script* pNewScript = new Script;
    pNewScript->Name = "npc_capital_teleporter";
    pNewScript->pGossipHello = &GossipHello_npc_capital_teleporter;
    pNewScript->pGossipSelect = &GossipSelect_npc_capital_teleporter;
    pNewScript->RegisterSelf();
}
