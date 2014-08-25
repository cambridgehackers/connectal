
#ifndef REGEX_MATCHER_H
#define REGEX_MATCHER_H

typedef int REGEX_STATE; // Could probably be 8 bits.

// Function pointers which are given as arguments to define the DFA.
typedef char (*REGEX_CHAR_MAP)(char);
typedef REGEX_STATE (*REGEX_STATE_MAP)(REGEX_STATE);
typedef REGEX_STATE (*REGEX_STATE_TRANSITION)(REGEX_STATE, char);
typedef bool (*REGEX_ACCEPT_STATES)(REGEX_STATE);

class REGEX_MATCHER
{
  public:
    REGEX_MATCHER(const char* pattern_name);
    REGEX_MATCHER(REGEX_CHAR_MAP cm, REGEX_STATE_MAP sm, REGEX_STATE_TRANSITION tr, REGEX_ACCEPT_STATES as, const char* pattern_name);
   ~REGEX_MATCHER();
  
   REGEX_STATE getState() { return state; }
   void setState(REGEX_STATE s) { state = s; }
   const char* getName() { return patternName; }

   bool processChar(char c);

  protected:
    const char* patternName;
    bool enabled;
    REGEX_STATE state;
    REGEX_CHAR_MAP charMap;
    REGEX_STATE_MAP stateMap;
    REGEX_STATE_TRANSITION stateTransition;
    REGEX_ACCEPT_STATES acceptStates;
};

#endif
