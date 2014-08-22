
#include <iostream>

#include "regex-matcher.h"

// This constructor makes a disabled regular expression matcher that
// has no DFA and never matches.
REGEX_MATCHER::REGEX_MATCHER(const char* pattern_name) : 
    patternName(pattern_name), enabled(false)
{
}

// This constructor makes an actual regular expression matcher
REGEX_MATCHER::REGEX_MATCHER(REGEX_CHAR_MAP cm, REGEX_STATE_MAP sm, REGEX_STATE_TRANSITION tr, REGEX_ACCEPT_STATES as, const char* pattern_name) :
    state(0), charMap(cm), stateMap(sm), stateTransition(tr), acceptStates(as), patternName(pattern_name), enabled(true)
{
}

REGEX_MATCHER::~REGEX_MATCHER()
{
}

bool 
REGEX_MATCHER::processChar(char c)
{
    if (!enabled) return false;

    // Start by mapping the char down to reduce the state size.
    char mapped_char = charMap(c);
    // Use the state mapping function to adjust to the reduced input space.
    REGEX_STATE mapped_state = stateMap(state);
    // Use the state transition function to determine the next state.
    REGEX_STATE next_state = stateTransition(mapped_state, mapped_char);

    // Was this state one that indicates a match?
    if (acceptStates(next_state))
    {
        // Reset the state to scan for more matches.
        // This also means we won't be stuck in the accept state.
        state = 0;
        return true;
    }
    else
    {
        // Update the connection state with the new state.
        state = next_state;
        return false;
    }
}
