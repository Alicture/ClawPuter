#pragma once

void stateBroadcastBegin(const char* unicastTarget = nullptr);
void stateBroadcastTick(int state, int frame, const char* mode);
