//
//  AppDelegate.h
//  ReName-ObjC
//
//  Created by yosuke on 2018/02/12.
//  Copyright © 2018年 Yosuke.Nakayama. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DragDrop.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSString *sn_count;
    NSString *zero_count;
    NSString *start_num;
    NSString *Old_filePath;
    NSString *New_filePath;
    NSString *rename;
    NSString *distSerial;
    NSString *NewName;
    NSArray *oldContent;
    
    int count;
    int prf;     //連番の開始値。デフォルトは0
    int roop;   //書出しループの開始値
    int ketaFileNumber; //ファイルの連番の桁数
    
    long int AlrtMss;
    
    NSString *message;  //結果の文字列を代入する変数
    
    bool canceled;  //停止ボタンが押されたかどうかの判定
    __block int adjustFileNumber;   //offsetFileNumberを用いて算出される番号
}

@property (weak) IBOutlet DragDrop *Origin_Path;
@property (weak) IBOutlet DragDrop *Output_Path;
@property (weak) IBOutlet NSTextField *New_Name;
@property (weak) IBOutlet NSTextField *Include_str;

@property (weak) IBOutlet NSButton *Start_Serial_Btn;

@property (weak) IBOutlet NSButton *suffix_Btn;
@property (weak) IBOutlet NSButton *prefix_Btn;

@property (weak) IBOutlet NSButton *Digit_Check;
@property (weak) IBOutlet NSButton *Digit_tw_Btn;
@property (weak) IBOutlet NSButton *Digit_th_Btn;
@property (weak) IBOutlet NSButton *Digit_fo_Btn;
@property (weak) IBOutlet NSButton *Digit_fi_Btn;
@property (weak) IBOutlet NSButton *Digit_si_Btn;
@property (weak) IBOutlet NSButton *Digit_se_Btn;
@property (weak) IBOutlet NSButton *Digit_ei_Btn;
@property (weak) IBOutlet NSButton *Digit_ni_Btn;
@property (weak) IBOutlet NSButton *Digit_te_Btn;

@property (weak) IBOutlet NSButton *Serial_Check_Btn;
@property (weak) IBOutlet NSTextField *number_text;

@property (weak) IBOutlet NSButton *not_underbar_Btn;

@property (weak) IBOutlet NSScrollView *TextBox;
@property (unsafe_unretained) IBOutlet NSTextView *logBox;

@property (weak) IBOutlet NSButton *leave_Origin_Check;

@property (weak) IBOutlet NSButton *exChangeBtn;
@property (weak) IBOutlet NSButton *Stop_Btn;

@property (weak) IBOutlet NSTextField *label1;
@property (weak) IBOutlet NSTextField *label2;

@property (weak) IBOutlet NSButton *selectBtnA;
@property (weak) IBOutlet NSButton *selectBtnB;

- (IBAction)exChange:(id)sender;
- (IBAction)Stop:(id)sender;

- (IBAction)sn_select:(id)sender;
- (IBAction)digit_select:(id)sender;
- (IBAction)tw_select:(id)sender;
- (IBAction)fldSelectA:(id)sender;
- (IBAction)fldSelectB:(id)sender;

-(void) allBtnOn;
-(void) allBtnOff;
-(void)digit_allOff;
-(long int)alertMessage:(NSString *)Mess Text2:(NSString *)Info FirstBtn:(NSString *)fBtn;
-(void)alertSecondMessage:(NSString *)Mess Text2:(NSString *)Info;
-(void)mkdir:(NSString *)opPath;
-(void)Column_Sort:(int)prf;

@end

