//
// Handles writing out debug data that can be used by emulator or other tools
// to single step through code.
//

#ifndef __DEBUG_INFO_H
#define __DEBUG_INFO_H

int openDebugInfo(const char *filename);
void closeDebugInfo();
void debugInfoSetSourceFile(const char *fname);
void addLineMapping(int programCounter, int lineNum);

#endif
