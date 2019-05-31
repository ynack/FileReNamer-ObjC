//
//  DragDrop.h
//  ReName-ObjC
//
//  Created by nakayama on 2018/02/13.
//  Copyright © 2018年 Yosuke.Nakayama. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface DragDrop : NSTextField
{
    NSMutableArray *DDArray;
    NSNotification *editNotif;
    NSNotification *myESCNotif;
    NSNotification *myDELNotif;
    NSString *myESCStr;
    NSString *myDELStr;    
    NSString *pstrPath;
    
    int _nAcceptableObjectType; //ドロップ可能オブジェクト種別
    int myALTflag;
    
    BOOL _bInDragging;          //ドラッグ中フラグ
}

-(void)setEditNotif:(NSString *)notifStr;
-(NSArray *)fileListInDraggingInfo:(id <NSDraggingInfo>)info;
-(NSArray *)dragDropNameArray;
-(int)dragDropCount;

@end
