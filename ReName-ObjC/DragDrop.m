//
//  DragDrop.m
//  ReName-ObjC
//
//  Created by nakayama on 2018/02/13.
//  Copyright © 2018年 Yosuke.Nakayama. All rights reserved.
//

#import "DragDrop.h"
#import "AppDelegate.h"

#define ACCEPT_BOTH 0   //ファイルもフォルダもドラッグ可
#define ACCEPT_FILE 1   //ファイルをドラッグ可
#define ACCEPT_DIRECTORY 2   //フォルダをドラッグ可

@implementation DragDrop

-(void)awakeFromNib
{
    if([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)])
    {
        [super awakeFromNib];
    }
    
    //ドラッグ受付対象の登録（ファインダーからのファイルパス）
    NSArray *parrTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
    [self registerForDraggedTypes:parrTypes];
    DDArray = [NSMutableArray arrayWithObjects:@"", nil];
    
    //インスタンス変数の初期化
    _bInDragging = NO;
    _nAcceptableObjectType = ACCEPT_BOTH;
    
    myALTflag = 0;
    myESCStr = @"myESCNotif";
    myESCNotif = [NSNotification notificationWithName:myESCStr object:self];
    myDELStr = @"myDELNotif";
    myDELNotif = [NSNotification notificationWithName:myDELStr object:self];
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{

    BOOL bRet = [self acceptableObject:sender];
    if(bRet != YES)
    {
        return NSDragOperationNone;
    }
    
    //ドラッグ中状態に設定
    [self setInDragging:YES];
    
    return NSDragOperationGeneric;
}

-(void)draggingExited:(id<NSDraggingInfo>)sender
{
    //NSLog(@"Exited enter");
    [self setInDragging:NO];
    
    return;
}

-(NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        return NSDragOperationGeneric;
    }
    else
    {
        return NSDragOperationNone;
    }
}

-(void)draggingEnded:(id<NSDraggingInfo>)sender
{
   // NSLog(@"End enter");
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    //NSLog(@"prepare enter");
    return YES;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSArray *parrFiles = [self fileListInDraggingInfo:sender];
    if([parrFiles count] > 1)
    {
        //複数のドラッグは受付不可
        return NO;
    }
    
    //ドラッグされたファイルパス取得
    pstrPath = [parrFiles objectAtIndex:0];

    //パス文字列をテキストフィールドに設定
    [self setStringValue:pstrPath];
    
    return YES;
}

//ドロップ処理の完了通知
-(void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    if(editNotif)
    {
        [[NSNotificationCenter defaultCenter] postNotification:editNotif];
    }

    [self setInDragging:NO];
}

-(void)setEditNotif:(NSString *)notifStr
{
    if(editNotif)
    {
        return;
    }

    editNotif = [NSNotification notificationWithName:notifStr object:self];
}

-(NSString *)returnPath:(NSString *)rPath
{
    return rPath;
}

//ドラッグ中のフィールド枠の強調表示用にオーバーライド
-(void)drawRect:(NSRect)aRect
{
    //まずはNSTextFieldとしての描画を実行
    [super drawRect:aRect];
    
    if(_bInDragging == YES)
    {
        //ドラッグ中はフレーム枠を強調表示
        [[NSColor selectedControlColor] set];
        NSFrameRectWithWidth(aRect, 3.0);
    }
}

//ドラッグ情報からファイルリストを取得
-(NSArray *)fileListInDraggingInfo:(id <NSDraggingInfo>)info
{
    //ペースボードオブジェクト取得
    NSPasteboard *pboard = [info draggingPasteboard];
    //ドラッグされたファイルの一覧取得
    NSArray *parrFiles = [pboard propertyListForType:NSFilenamesPboardType];
    
    return parrFiles;
}

//ドロップ可能オブジェクト種別（ファイル & ディレクトリ or 両方）の設定
-(void)setAcceptableObjectType:(int)nType
{
    _nAcceptableObjectType = nType;
}

//現在ドラッグ中のオブジェクトが自フィールドにドロップ可能か判定する
-(BOOL)acceptableObject:(id <NSDraggingInfo>)info
{
    NSArray *parrFiles;
    NSString *pstrPath;
    NSFileManager *poFM = [NSFileManager defaultManager];
    BOOL bRet, bDir;
    
    //ドラッグされたファイルの一覧取得
    parrFiles = [self fileListInDraggingInfo:info];
    if([parrFiles count] > 1)
    {
        //複数のドラッグは受付不可
        return NO;
    }
    
    //ドラッグされたパスが受付可能であるかチェック
    pstrPath = [parrFiles objectAtIndex:0];
    bRet = [poFM fileExistsAtPath: pstrPath isDirectory:&bDir];
    if(bRet != YES)
    {
        //パスが存在しなかった場合
        return NO;
    }
    
    switch(_nAcceptableObjectType)
    {
        case ACCEPT_FILE:
            //ファイルのみ
            return (bDir == YES)? NO: YES;
            break;
        
        case ACCEPT_DIRECTORY:
            return bDir;
            break;
            
        default:
            //両方OK
            return YES;
    }
}

-(void)setInDragging:(BOOL)flag
{
    //状態変更
    _bInDragging = flag;
    
    //強調表示生業のために強制再描画要求
    [self setNeedsDisplay:YES];
}

-(NSArray *)dragDropNameArray
{
    return DDArray;
}

-(int)dragDropCount
{
    return (int)[DDArray count];
}

@end
