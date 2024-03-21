//Phil Nevins
//ECE 372 DP2 Part 2

#include <stdio.h>

//Define Sections
#define HWREG(x) (*((volatile unsigned int *) (x)))

//Define Bases
#define CNTRL_MOD 0x44E10000
#define CM_PER 0x44E00000
#define I2C2 0x4819C000

//Define Offsets
#define spi0_d0 0x954
#define spi0_sclk 0x950
#define I2C_PSC 0xB0
#define I2C_SCLL 0xB4
#define I2C_SCLH 0xB8
#define I2C_CON 0xA4
#define I2C_IRQSTATUS_RAW 0x24
#define I2C_OA 0xA8
#define I2C_CNT 0x98
#define I2C_DATA 0x9C
#define I2C_SA 0xAC
#define I2C_SYSC 0x10

//Define Slave Addresses
#define LED2_ON_H 0x0F
#define LED2_OFF_H 0x11
#define LED3_ON_H 0x13
#define LED3_OFF_H 0x15
#define LED4_ON_H 0x17
#define LED4_OFF_H 0x19
#define LED5_ON_H 0x1B
#define LED5_OFF_H 0x1D
#define LED6_ON_H 0x1F
#define LED6_OFF_H 0x21
#define LED7_ON_H 0x23
#define LED7_OFF_H 0x25
#define ALL_ON 0xFB
#define ALL_OFF 0xFD
#define PRE_SCALE 0xFE
#define MODE1 0x00
#define MODE2 0x01

//Declare Functions
void int_I2C2();
void PCA9865_INIT();
void STEP1();
void STEP2();
void STEP3();
void STEP4();
void WAIT(int i);
void SEND(int address, int data);
void TURN_OFF(void);
void init(void);
int i, n;

int main(void){

    int_I2C2();
    PCA9865_INIT();

    for(i = 0; i < 60; i++)
    {
        STEP1();
        asm("NOP");

        asm("NOP");
        STEP2();

        asm("NOP");
        STEP3(); //brake

        asm("NOP");
        STEP4();

        //WAIT(400000);
        asm("NOP");
        STEP1();
    }

    asm("NOP");

    SEND(ALL_OFF, 0x10);

    return 0;
}

void int_I2C2()
{
    HWREG(CM_PER + 0x44) = 0x2;     //Turn on I2C2 Clock Module
    HWREG(CNTRL_MOD + spi0_d0) = 0x32;    //Configure Pin 21 as I2C2_SCL
    HWREG(CNTRL_MOD + spi0_sclk) = 0x32;    //Configure Pin 22 as I2C2_SDA
    HWREG(I2C2 + I2C_SYSC) = 0x02;    //Software reset
    HWREG (I2C2 + I2C_PSC) = 0x00;    //Configure Pre-Scale I2C2 register
    HWREG(I2C2 + I2C_SCLL) = 0x08;    //Configure the I2C low time register
    HWREG(I2C2 + I2C_SCLH) = 0x0A;   //Configure the I2C high time register
    HWREG(I2C2 + I2C_OA) = 0x0;    //Configure I2C Own Address register
    HWREG(I2C2 + I2C_SA) = 0xE0;    //Set slave address as 0xE0
    HWREG(I2C2 + I2C_CON) = 0x8600;    //Configure I2C_CON Register
}

void SEND(int address, int data)
{

    HWREG(I2C2 + I2C_CNT) = 0x02;     //configure I2C_CNT register with number of bytes to be transfered
    if(!(HWREG(I2C2 + I2C_IRQSTATUS_RAW) & 0x1000))    // If the bus busy Bit 12 = 0
    {
        //Write 0x01 to CON register to initiat start transfer condition
        //WAIT(5000);
        HWREG(I2C2 + I2C_CON) = 0x8603;
        // If XRDY bit 4 = 1
        if((HWREG(I2C2 + I2C_IRQSTATUS_RAW) & (0x10))){


            //Load I2C Data reg with address to send out on SDA
            HWREG(I2C2 + I2C_DATA) = address;
            WAIT(5000);
            //data to output
            HWREG(I2C2 + I2C_DATA) = data;
            WAIT(5000);
            asm("NOP");
            }

        else{
            //jump back to top of send_out function and check bits 12 and 4 again);
            SEND(address, data);
        }
    }
    else{
        SEND(address, data);

}
}

void PCA9865_INIT(void)
{
    SEND(MODE1, 0x11);    //Sending 0x10 to MODE1 enabling sleep reg to enable write on PRE_SCALE register
    //WAIT(5000);
    SEND(PRE_SCALE, 0x05);    //setting prescale for 1kHz
    //WAIT(5000);
    SEND(MODE1, 0x01);    //Taking MODE1 out of sleep and maintainging repsonse to all call
    //WAIT(5000);
    SEND(MODE2, 0x04);    //setting totem pole
    init();
}

void STEP1(void)
{
    TURN_OFF();
    SEND(LED3_ON_H, 0x10);
    WAIT(5000);
    SEND(LED5_ON_H, 0x10);
    WAIT(5000);
}

void STEP2(void)
{
    TURN_OFF();
    SEND(LED4_ON_H, 0x10);
    WAIT(5000);
    SEND(LED6_ON_H, 0x10);
    WAIT(5000);
}

void STEP3(void)
{
    TURN_OFF();
    SEND(LED6_ON_H, 0x10);
    WAIT(5000);
    SEND(LED3_ON_H, 0x10);
    WAIT(5000);
}

void STEP4(void)
{
    TURN_OFF();
    SEND(LED5_ON_H, 0x10);
    WAIT(5000);
    SEND(LED4_ON_H, 0x10);
    WAIT(5000);
}


void OFF(void)
{
    SEND(LED6_ON_H, 0x00);
    WAIT(5000);
    SEND(LED5_ON_H, 0x00);
    WAIT(5000);
    SEND(LED4_ON_H, 0x00);
    WAIT(5000);
    SEND(LED3_ON_H, 0x00);
    WAIT(5000);
    asm("NOP");
}

void init(void)
{

    SEND(ALL_ON, 0x00);    //Turning off off all call

    SEND(ALL_OFF, 0x00);    //turning off on all LED outputs
    WAIT(5000);

    SEND(LED7_ON_H, 0x10);    // Sending 0x10 to LED7 to hold PWMB high
    WAIT(5000);

    SEND(LED2_ON_H, 0x10);    // Sending 0x10 to LED2 driver out (i.e. PWMA)
    WAIT(5000);
}

void WAIT(int i)
{
    for(n = 0; n < i; n++)
{
    asm("NOP");
}
}
