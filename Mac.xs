#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Devices.h>

#if PRAGMA_STRUCT_ALIGN
         #pragma options align=mac68k
#endif
#if PRAGMA_STRUCT_ALIGN
         #pragma options align=reset
#endif

  /* Ã status status */
  /* Ã info info */
  /* Ã eject b */
  /* Ã pause b */
  /* Ã continue b */
  /* Ã play ([track]) b */
  /* Ã stop b */
  /* volume ([level]) level */
  /* forward info */
  /* reverse info */
  /* scan_forward info */
  /* scan_reverse info */
  /* play_mode ? */

MODULE = AudioCD::Mac		PACKAGE = AudioCD::Mac

short
_GetDrive()
    PREINIT:
    short drvRefNum;

    CODE:
    if (gLastMacOSErr = OpenDriver("\p.AppleCD", &drvRefNum))
        XSRETURN_UNDEF;

    RETVAL = drvRefNum;
    
    OUTPUT:
    RETVAL

char *
_GetToc(drvRefNum)
    short drvRefNum;
    PREINIT:
    CntrlParam myPB;
    char myToc[512];
    char retToc[2048];
    int cToc;

    CODE:
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 100;
    myPB.csParam[0] = 4;
    *(Ptr *)&myPB.csParam[1] = myToc;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    for (cToc = 1; cToc<511; cToc+=5) {
        if (myToc[cToc] == 0) {
            sprintf(retToc, "%s%d\t%d\t%d\t%d\n", retToc,
                myToc[cToc+1], myToc[cToc+2], myToc[cToc+3], myToc[cToc+4]);
        } else {
            cToc = 512;
        }
    }
    RETVAL = retToc;

    OUTPUT:
    RETVAL

short
_Status(drvRefNum)
    short drvRefNum;

    CODE:
    CntrlParam myPB;
    short status;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 107;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    status = ((myPB.csParam[0] >> 8) & 255);
    RETVAL = status;

    OUTPUT:
    RETVAL

char *
_Eject(drvRefNum)
    short drvRefNum;

    CODE:
    OSErr           myErr;
    HParamBlockRec  myVol;
    const short     kMaxRefNums = 8;
    short           vRefNums[kMaxRefNums+1];
    short           numVolumes = 0;
    char            vols[255];

    myVol.volumeParam.ioCompletion = 0L;
    myVol.volumeParam.ioVolIndex = 0;

    do {
        myVol.volumeParam.ioVolIndex++;
        myErr = PBHGetVInfoSync(&myVol);
        if (!myErr && myVol.volumeParam.ioVDRefNum == drvRefNum) {
            vRefNums[numVolumes] = myVol.volumeParam.ioVRefNum;
            sprintf(vols, "%s\t%d", vols, vRefNums[numVolumes]);
            numVolumes++;
        }
    } while (!myErr && numVolumes < kMaxRefNums);

    if (numVolumes == 0) {
        CntrlParam myPB;
        myPB.ioCompletion = 0;
        myPB.ioVRefNum = 1;
        myPB.ioCRefNum = drvRefNum;
        myPB.csCode = 7;

        if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
            XSRETURN_UNDEF;

        RETVAL = "1";
    } else {
        RETVAL = vols;
    }


    OUTPUT:
    RETVAL

int
_Pause(drvRefNum, status)
    short drvRefNum;
    short status;

    CODE:
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 105;

    if (status == 1) {
        myPB.csParam[0] = 0;
        myPB.csParam[1] = 0;
    } else if (status == 0) {
        myPB.csParam[0] = 1;
        myPB.csParam[1] = 1;    
    } else {
        XSRETURN_UNDEF;
    }

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

int
_Continue(drvRefNum, status)
    short drvRefNum;
    short status;

    CODE:
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 105;

    if (status == 1) {
        myPB.csParam[0] = 0;
        myPB.csParam[1] = 0;
    } else {
        XSRETURN_UNDEF;
    }

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

int
_Stop(drvRefNum)
    short drvRefNum;

    CODE:
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 106;
    myPB.csParam[0] = 0;
    myPB.csParam[1] = 0;
    myPB.csParam[2] = 0;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

int
_Play(drvRefNum, start1, start2, end1, end2)
    short drvRefNum;
    short start1;
    short start2;
    short end1;
    short end2;

    CODE:
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 106;
    myPB.csParam[0] = 2;
    myPB.csParam[1] = end1;
    myPB.csParam[2] = end2;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    myPB.csCode = 104;
    myPB.csParam[1] = start1;
    myPB.csParam[2] = start2;
    myPB.csParam[3] = 0;
    myPB.csParam[4] = 9;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

int
_SetVolume(drvRefNum, vol_l, vol_r)
    short drvRefNum;
    short vol_l;
    short vol_r;

    CODE:
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 109;
    myPB.csParam[0] = (vol_l << 8) | vol_r;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    RETVAL = 1;

    OUTPUT:
    RETVAL

char *
_GetVolume(drvRefNum)
    short drvRefNum;

    CODE:
    char vol[8];
    CntrlParam myPB;
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 112;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    sprintf(vol, "%u\t%u", (myPB.csParam[0] >> 8) & 255,
        myPB.csParam[0] & 255);
    RETVAL = vol;

    OUTPUT:
    RETVAL

char *
_Info(drvRefNum)
    short drvRefNum;

    CODE:
    CntrlParam myPB;
    char info[30];
    myPB.ioCompletion = 0;
    myPB.ioVRefNum = 1;
    myPB.ioCRefNum = drvRefNum;
    myPB.csCode = 101;

    if (gLastMacOSErr = PBControl((ParmBlkPtr)&myPB, false))
        XSRETURN_UNDEF;

    sprintf(info, "%d\t%d\t%d\t%d\t%d\t%d\t%d\t",
        myPB.csParam[0] & 255,
        myPB.csParam[1] & 255,
        (myPB.csParam[2] >> 8) & 255,
        myPB.csParam[2] & 255,
        (myPB.csParam[3] >> 8) & 255,
        myPB.csParam[3] & 255,
        (myPB.csParam[4] >> 8) & 255
    );

    RETVAL = info;

    OUTPUT:
    RETVAL

