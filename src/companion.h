#pragma once
#include <M5Cardputer.h>
#include "utils.h"

enum class CompanionState {
    IDLE,
    HAPPY,
    SLEEP,
    TALK,
    STRETCH,   // spontaneous stretch
    LOOK       // spontaneous look around
};

class Companion {
public:
    void begin(M5Canvas& canvas);
    void update(M5Canvas& canvas);
    void handleKey(char key);

    // External triggers
    void triggerHappy();
    void triggerTalk();
    void triggerIdle();

    CompanionState getState() const { return state; }
    int getFrameIndex() const { return frameIndex; }

    // Sound effects
    static void playKeyClick();
    static void playNotification();
    static void playHappy();

private:
    CompanionState state = CompanionState::IDLE;
    int frameIndex = 0;
    Timer animTimer{500};
    Timer idleTimeout{30000};  // 30s → sleep
    Timer clockTimer{1000};
    Timer spontaneousTimer{8000};  // random actions every 8-15s
    unsigned long stateStartTime = 0;

    // Star twinkling
    struct Star { int x, y; bool visible; };
    static constexpr int MAX_STARS = 12;
    Star stars[MAX_STARS];
    Timer starTimer{800};

    // Day/night
    bool isNightTime();
    int currentHour();

    void drawBackground(M5Canvas& canvas);
    void drawCharacter(M5Canvas& canvas);
    void drawClock(M5Canvas& canvas);
    void drawSleepZ(M5Canvas& canvas);
    void drawStatusText(M5Canvas& canvas);
    void drawDayElements(M5Canvas& canvas);

    void setState(CompanionState newState);
    void initStars();
    void trySpontaneousAction();

    // Draw a sprite with transparency
    void drawSprite16(M5Canvas& canvas, int x, int y, const uint16_t* data);
};

// Boot animation (called from main.cpp)
void playBootAnimation(M5Canvas& canvas);

// Mode transition animation
void playTransition(M5Canvas& canvas, bool toChat);
