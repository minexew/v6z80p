#ifndef JOYSTICK_H
#define JOYSTICK_H


// prototypes
//void Joystick_SelectJoystickPort(byte portNumber);
void Joystick_GetInput(void);

void Joystick_GetInputForPlayer(byte playerNumber);
void Joystick_CheckInputAutoSwithForPlayer(byte playerNumber);
void Joystick_CheckInputAutoSwith(void);
BOOL Joystick_IsSecondJoyNeedToBeReaded(void);


#endif /* JOYSTICK_H */