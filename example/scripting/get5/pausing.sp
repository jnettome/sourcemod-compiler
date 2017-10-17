public bool Pauseable() {
  return g_GameState >= GameState_KnifeRound && g_PausingEnabledCvar.IntValue != 0;
}

public Action Command_Pause(int client, int args) {
  if (!Pauseable() || IsPaused())
    return Plugin_Handled;

  char pausePeriodString[32];
  if (g_ResetPausesEachHalfCvar.IntValue != 0) {
    Format(pausePeriodString, sizeof(pausePeriodString), " %t", "PausePeriodSuffix");
  }

  MatchTeam team = GetClientMatchTeam(client);

  if (client == 0) {
    Pause();
    Get5_MessageToAll("%t", "AdminForcePauseInfoMessage");
  } else {
    int maxPauses = g_MaxPausesCvar.IntValue;
    if (maxPauses > 0 && g_TeamPausesUsed[team] >= maxPauses && IsPlayerTeam(team)) {
      Get5_Message(client, "%t", "MaxPausesUsedInfoMessage", maxPauses, pausePeriodString);
      return Plugin_Handled;
    }
  }

  int maxPauseTime = g_MaxPauseTimeCvar.IntValue;
  if (maxPauseTime > 0 && g_TeamPauseTimeUsed[team] >= maxPauseTime && IsPlayerTeam(team)) {
    Get5_Message(client, "%t", "MaxPausesTimeUsedInfoMessage", maxPauseTime, pausePeriodString);
    return Plugin_Handled;
  }

  g_TeamReadyForUnpause[MatchTeam_Team1] = false;
  g_TeamReadyForUnpause[MatchTeam_Team2] = false;

  // If the pause will need explicit resuming, we will create a timer to poll the pause status.
  bool need_resume = Pause(g_FixedPauseTimeCvar.IntValue, MatchTeamToCSTeam(team));
  if (IsPlayer(client)) {
    Get5_MessageToAll("%t", "MatchPausedByTeamMessage", client);
  }

  if (IsPlayerTeam(team)) {
    if (need_resume) {
      CreateTimer(1.0, Timer_PauseTimeCheck, team, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    g_TeamPausesUsed[team]++;

    pausePeriodString = "";
    if (g_ResetPausesEachHalfCvar.IntValue != 0) {
      Format(pausePeriodString, sizeof(pausePeriodString), " %t", "PausePeriodSuffix");
    }

    if (g_MaxPausesCvar.IntValue > 0) {
      int pausesLeft = g_MaxPausesCvar.IntValue - g_TeamPausesUsed[team];
      if (pausesLeft == 1 && g_MaxPausesCvar.IntValue > 0) {
        Get5_MessageToAll("%t", "OnePauseLeftInfoMessage", g_FormattedTeamNames[team], pausesLeft,
                          pausePeriodString);
      } else if (g_MaxPausesCvar.IntValue > 0) {
        Get5_MessageToAll("%t", "PausesLeftInfoMessage", g_FormattedTeamNames[team], pausesLeft,
                          pausePeriodString);
      }
    }
  }

  return Plugin_Handled;
}

public Action Timer_PauseTimeCheck(Handle timer, int data) {
  if (!Pauseable() || !IsPaused() || g_FixedPauseTimeCvar.IntValue != 0) {
    return Plugin_Stop;
  }

  char pausePeriodString[32];
  if (g_ResetPausesEachHalfCvar.IntValue != 0) {
    Format(pausePeriodString, sizeof(pausePeriodString), " %t", "PausePeriodSuffix");
  }

  MatchTeam team = view_as<MatchTeam>(data);
  int timeLeft = g_MaxPauseTimeCvar.IntValue - g_TeamPauseTimeUsed[team];

  // Only count against the team's pause time if we're actually in the freezetime
  // pause and they haven't requested an unpause yet.
  if (InFreezeTime() && !g_TeamReadyForUnpause[team]) {
    g_TeamPauseTimeUsed[team]++;

    if (timeLeft == 10) {
      Get5_MessageToAll("%t", "PauseTimeExpiration10SecInfoMessage", g_FormattedTeamNames[team]);
    } else if (timeLeft % 30 == 0) {
      Get5_MessageToAll("%t", "PauseTimeExpirationInfoMessage", g_FormattedTeamNames[team],
                        timeLeft, pausePeriodString);
    }
  }

  if (timeLeft <= 0) {
    Get5_MessageToAll("%t", "PauseRunoutInfoMessage", g_FormattedTeamNames[team]);
    Unpause();
    return Plugin_Stop;
  }

  return Plugin_Continue;
}

public Action Command_Unpause(int client, int args) {
  if (!IsPaused())
    return Plugin_Handled;

  // Let console force unpause
  if (client == 0) {
    Unpause();
    Get5_MessageToAll("%t", "AdminForceUnPauseInfoMessage");
  } else {
    if (g_FixedPauseTimeCvar.IntValue != 0) {
      return Plugin_Handled;
    }

    MatchTeam team = GetClientMatchTeam(client);
    g_TeamReadyForUnpause[team] = true;

    if (g_TeamReadyForUnpause[MatchTeam_Team1] && g_TeamReadyForUnpause[MatchTeam_Team2]) {
      Unpause();
      if (IsPlayer(client)) {
        Get5_MessageToAll("%t", "MatchUnpauseInfoMessage", client);
      }
    } else if (g_TeamReadyForUnpause[MatchTeam_Team1] && !g_TeamReadyForUnpause[MatchTeam_Team2]) {
      Get5_MessageToAll("%t", "WaitingForUnpauseInfoMessage", g_FormattedTeamNames[MatchTeam_Team1],
                        g_FormattedTeamNames[MatchTeam_Team2]);
    } else if (!g_TeamReadyForUnpause[MatchTeam_Team1] && g_TeamReadyForUnpause[MatchTeam_Team2]) {
      Get5_MessageToAll("%t", "WaitingForUnpauseInfoMessage", g_FormattedTeamNames[MatchTeam_Team2],
                        g_FormattedTeamNames[MatchTeam_Team1]);
    }
  }

  return Plugin_Handled;
}
