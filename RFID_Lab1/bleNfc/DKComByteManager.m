//
//  ComByteManager.m
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "DKComByteManager.h"

@interface DKComByteManager()

@end

@implementation DKComByteManager

int RcvFrameType;
int RcvFrameNum;
Byte RcvCommand;
Byte RcvData[MAX_FRAME_DATA_LEN] = {0};
int RcvDataLen;
Byte RcvComRunStatus[2] = {0};
int last_frame_num = 0;

-(id)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}
-(id)initWhitDelegate:(id)theDelegate {
    self = [super init];
    if (self) {
        
    }
    self.delegate = theDelegate;
    return self;
}
-(Byte)getCmd{
    return RcvCommand;
}
-(BOOL)getCmdRunStatus{
    return (RcvComRunStatus[0] == (Byte) 0x90);
}
-(NSInteger)getRcvDataLen{
    return RcvDataLen;
}
-(NSData *)getRcvData {
    if (RcvDataLen == 0) {
        return nil;
    }
    return [NSData dataWithBytes:RcvData length:RcvDataLen];
}
-(BOOL)rcvData:(NSData *)rcvData{
    int this_frame_num = 0;
    int status = 0;
    Byte *bytes = (Byte *)[rcvData bytes];
    
    //提取帧类型是开始帧还是后续帧
    if ( (bytes[0] & 0xC0) == 0x00) {     //开始帧
        //开始帧必须大于4位
        if (rcvData.length < 4) {
            return false;
        }
        RcvFrameType = Start_Frame;
        //如果是开头帧，则提取后续帧个数和命令
        RcvFrameNum = bytes[0] & 0x3F;
        RcvCommand = bytes[1];
        RcvComRunStatus[0] = bytes[2];
        RcvComRunStatus[1] = bytes[3];
        RcvDataLen = (int)rcvData.length - 4;
        memcpy(RcvData, &bytes[4], RcvDataLen);
        last_frame_num = 0;
        
        if (RcvFrameNum > 0) {
            status = Rcv_Status_Follow;
        }
        else {
            status = Rcv_Status_Complete;
        }
    }
    else if ((bytes[0] & 0xC0) == 0xC0) {   //后续帧
        //后续帧必须大于2位
        if (rcvData.length < 2) {
            last_frame_num = 0;
            RcvFrameType = 0;
            RcvFrameNum = 0;
            RcvCommand = 0;
            for (int i=0; i<MAX_FRAME_DATA_LEN; i++) {
                RcvData[i] = 0;
            }
            RcvDataLen = 0;
            RcvComRunStatus[0] = 0;
            RcvComRunStatus[1] = 0;
            return false;
        }
        this_frame_num = bytes[0] & 0x3F;
        if (this_frame_num != (last_frame_num + 1) ) {        //帧序号不对
            status = Rcv_Status_Idle;
        }
        else if (this_frame_num == RcvFrameNum) {  //接收完成
            if ( MAX_FRAME_DATA_LEN < (RcvDataLen + rcvData.length - 1) ) {
                status = Rcv_Status_Idle;
            }
            else {
                memcpy(&RcvData[RcvDataLen], &bytes[1], rcvData.length - 1);
                RcvDataLen += rcvData.length - 1;
                status = Rcv_Status_Complete;
            }
        }
        else {                                               //接收中
            if ( MAX_FRAME_DATA_LEN < (RcvDataLen + rcvData.length - 1) ) {
                status = Rcv_Status_Idle;
            }
            else {
                last_frame_num = this_frame_num;
                memcpy(&RcvData[RcvDataLen], &bytes[1], rcvData.length - 1);
                RcvDataLen += rcvData.length - 1;
                status = Rcv_Status_Follow;
            }
        }
    }
    else {
        status = Rcv_Status_Idle;
    }
    
    //指令接收错误
    if (status == Rcv_Status_Idle) {
        last_frame_num = 0;
        RcvFrameType = 0;
        RcvFrameNum = 0;
        RcvCommand = 0;
        for (int i=0; i<MAX_FRAME_DATA_LEN; i++) {
            RcvData[i] = 0;
        }
        RcvDataLen = 0;
        RcvComRunStatus[0] = 0;
        RcvComRunStatus[1] = 0;
        return false;
    }
    
    //指令接收完成
    if (status == Rcv_Status_Complete) {  //接收完成、执行命令
        last_frame_num = 0;
        if (self.delegate && [self.delegate respondsToSelector:@selector(comByteManagerCallback: rcvData:)]) {
            [self.delegate comByteManagerCallback:YES rcvData:[self getRcvData]];
        }
    }
    
    return true;
}
-(NSData *)data_framing_single:(NSInteger)frame_type frameNum:(Byte)frame_num cmd:(Byte)command originalData:(NSData *)originalData {
    Byte frame_temp[20];
    int index = 0;
    int returnDataLen = 0;
    Byte *originalBytes = (Byte *)[originalData bytes];
    
    //帧个数判断
    if (frame_num > MAX_FRAME_NUM) {
        return nil;
    }
    
    if (originalData == nil) {
        return nil;
    }
    
    //起始数据帧
    if (frame_type == Start_Frame) {
        //数据长度过长判断
        if (originalData.length > (MAX_FRAME_LEN - 2)) {
            return nil;
        }
        
        returnDataLen = (int)originalData.length + 2;
        frame_temp[index++] = frame_num;
        frame_temp[index++] = command;
    }
    else {   //后续数据帧
        //数据长度过长判断
        if (originalData.length > (MAX_FRAME_LEN - 1)) {
            return nil;
        }
        
        returnDataLen = (int)originalData.length + 1;
        frame_temp[index++] = (Byte) (0xC0 | frame_num);
    }
    
    //数据域
    for (int i=0; i<originalData.length; i++) {
        frame_temp[index++] = originalBytes[i];
    }
    
    return [NSData dataWithBytes:frame_temp length:returnDataLen];
}
-(NSData *)data_framing_full:(Byte)command sendData:(NSData *)sendData {
    Byte frame_temp[MAX_FRAME_LEN];
    Byte returnFrame[MAX_FRAME_DATA_LEN];
    int  returnDataLen = 0;
    int frame_num = 0;
    int frame_len = 0;
    int index = 0;
    int copy_data_len;
    int i = 0;
    Byte *pSend_data = (Byte *)[sendData bytes];
    int send_data_len = (int)sendData.length;
    
    //计算帧的个数
    if (send_data_len <= (MAX_FRAME_LEN - 2)) {
        frame_num = 0;
        returnDataLen = send_data_len + 2;
    }
    else {
        frame_num = (send_data_len - (MAX_FRAME_LEN - 2)) / (MAX_FRAME_LEN - 1);
        if (((send_data_len - (MAX_FRAME_LEN - 2)) % (MAX_FRAME_LEN - 1)) > 0) {
            returnDataLen = frame_num * 20/*中间帧*/ + 20/*第一帧*/ + ((send_data_len - (MAX_FRAME_LEN - 2)) % (MAX_FRAME_LEN - 1)) + 1/*最后一帧*/;
            frame_num++;
        }
        else {
            returnDataLen = frame_num * 20/*后续帧*/ + 20/*第一帧*/;
        }
    }
    
    
    //发送第一帧数据
    for (index=0; (index<send_data_len) && (index<(MAX_FRAME_LEN - 2)); index++) {
        frame_temp[index] = pSend_data[index];
    }
    
    NSData* frameSingleTemp  = [self data_framing_single:Start_Frame
                                                frameNum:frame_num
                                                     cmd:command
                                            originalData:[NSData dataWithBytes:frame_temp length:index]];
    //将组好的帧发送出去
    if ((frameSingleTemp != nil) && (frameSingleTemp.length != 0) && (frameSingleTemp.length <= MAX_FRAME_LEN)) {
        if (frameSingleTemp.length > MAX_FRAME_DATA_LEN) {
            return nil;
        }
        frame_len = (int)frameSingleTemp.length;
        Byte *frameSingleTempBytes = (Byte *)[frameSingleTemp bytes];
        memcpy(returnFrame, frameSingleTempBytes, frameSingleTemp.length);
    }
    else {
        return nil;
    }
    
    //如果还有后续帧
    if (frame_num > 0) {
        index = MAX_FRAME_LEN - 2;
        for (i=0; (i<frame_num) && (index<send_data_len); i++) {
            if ( (index + (MAX_FRAME_LEN - 1)) > send_data_len) {
                copy_data_len = ((send_data_len - (MAX_FRAME_LEN - 2)) % (MAX_FRAME_LEN - 1));
            }
            else {
                copy_data_len = MAX_FRAME_LEN - 1;
            }
            
            memcpy(frame_temp, &pSend_data[index], copy_data_len);
            index += copy_data_len;
            //组帧
            NSData* frameSingleTemp1 = [self data_framing_single:Follow_Frame
                                                        frameNum:(i + 1)
                                                             cmd:0
                                                    originalData:[NSData dataWithBytes:frame_temp length:copy_data_len]];
            //将组好的帧发送出去
            if ((frameSingleTemp1 != nil) && (frameSingleTemp1.length != 0) && (frameSingleTemp1.length <= MAX_FRAME_LEN)) {
                if ((frameSingleTemp1.length + frame_len) > MAX_FRAME_DATA_LEN) {
                    return nil;
                }
                Byte *frameSingleTemp1Bytes = (Byte *)[frameSingleTemp1 bytes];
                memcpy(&returnFrame[frame_len], frameSingleTemp1Bytes, frameSingleTemp1.length);
                frame_len += frameSingleTemp1.length;
            }
            else {
                return nil;
            }
        }
    }
    return [NSData dataWithBytes:returnFrame length:returnDataLen];
}

//A卡激活指令
+(NSData *)cardActivityComData{
    Byte comBytes[] = {0x00, ACTIVATE_PICC_COM};
    return [NSData dataWithBytes:comBytes length:2];
}
//指定激活卡片到哪一个协议层，例如cpu卡当成m1卡用时必须用此指令进行寻卡
+(NSData *)cardActivityComData:(Byte)protocolLayer {
    Byte comBytes[] = {0x00, ACTIVATE_PICC_COM, protocolLayer};
    return [NSData dataWithBytes:comBytes length:3];
}
//去激活指令(关闭天线)
+(NSData *)rfPowerOffComData{
    Byte comBytes[] = {0x00, ANTENNA_OFF_COM};
    return [NSData dataWithBytes:comBytes length:2];
}
//获取蓝牙读卡器电池电压指令
+(NSData *)getBtValueComData{
    Byte comBytes[] = {0x00, GET_BT_VALUE_COM};
    return [NSData dataWithBytes:comBytes length:2];
}
//获取设备版本号指令
+(NSData *)getVerisionsComData{
    Byte comBytes[] = {0x00, GET_VERSIONS_COM};
    return [NSData dataWithBytes:comBytes length:2];
}
//非接接口Apdu指令
+(NSData *)rfApduCmdData:(NSData *)ApduData{
    return [[[DKComByteManager alloc] init] data_framing_full:APDU_COM sendData:ApduData];
}
//非接接口bpdu指令
+(NSData *)rfBpduCmdData:(NSData *)BpduData{
    return [[[DKComByteManager alloc] init] data_framing_full:BPDU_COM sendData:BpduData];
}

+(NSData *)requestRfmSuicaBalance{
    Byte comBytes[] = {0x00, GET_SUICA_BALANCE_COM};
    return [NSData dataWithBytes:comBytes length:2];
}
+(NSData *)requestRfmFelicaRead:(NSData *)systemCode blockAddr:(NSData *)blockAddr{
    Byte comBytes[] = {0x00, FELICA_READ_COM};
    NSData *data1 = [NSData dataWithBytes:comBytes length:2];
    NSMutableData *cmdData = [[NSMutableData alloc] init];
    [cmdData appendData:data1];
    [cmdData appendData:systemCode];
    [cmdData appendData:blockAddr];
    return cmdData;
}
+(NSData *)ultralightCmdData:(NSData *)ulCmdData {
    return [[[DKComByteManager alloc] init] data_framing_full:ULTRALIGHT_CMD sendData:ulCmdData];
}
//Felica指令通道
//wOption:PH_EXCHANGE_DEFAULT/PH_EXCHANGE_BUFFER_FIRST/PH_EXCHANGE_BUFFER_CONT/PH_EXCHANGE_BUFFER_LAST
//wN:等待时间
//data：指令
+(NSData *)felicaCmdData:(NSInteger)wOption waitN:(NSInteger)wN data:(NSData *)data {
    Byte *dataByte = (Byte *)[data bytes];
    Byte bytesTem[data.length + 4];
    bytesTem[0] = (Byte) ((wOption >> 8) & 0x00ff);
    bytesTem[1] = (Byte) (wOption & 0x00ff);
    bytesTem[2] = (Byte) ((wN >> 8) & 0x00ff);
    bytesTem[3] = (Byte) (wN & 0x00ff);
    memcpy(&bytesTem[4], dataByte, data.length);
    NSData *cmdData = [NSData dataWithBytes:bytesTem length:data.length + 4];
    return [[[DKComByteManager alloc] init] data_framing_full:FELICA_COM sendData:cmdData];
}
//Mifare卡验证密码指令
+(NSData *)rfMifareAuthCmdData:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)pKey uid:(NSData *)pUid {
    Byte returnByte[2 + 1 + 1 + 6 + 4];
    Byte *keyBytes = (Byte *)[pKey bytes];
    Byte *uidBytes = (Byte *)[pUid bytes];
    
    returnByte[0] = 0x00;
    returnByte[1] = MIFARE_AUTH_COM;
    returnByte[2] = bBlockNo;
    returnByte[3] = bKeyType;
    memcpy(&returnByte[4], keyBytes, 6);
    memcpy(&returnByte[10], uidBytes, 4);
    
    return [NSData dataWithBytes:returnByte length:2 + 1 + 1 + 6 + 4];
}
//Mifarek卡数据交换指令
+(NSData *)rfMifareDataExchangeCmdData:(NSData *)data {
    return [[[DKComByteManager alloc] init] data_framing_full:MIFARE_COM sendData:data];
}
//通信协议测试通道指令
+(NSData *)getTestChannelData:(NSData *)data {
    return [[[DKComByteManager alloc] init] data_framing_full:PAL_TEST_CHANNEL sendData:data];
}
@end











