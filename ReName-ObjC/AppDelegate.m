//
//  AppDelegate.m
//  ReName-ObjC
//
//  Created by yosuke on 2018/02/12.
//  Copyright © 2018年 Yosuke.Nakayama. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [_Start_Serial_Btn setState:0];
    [_Digit_Check setState:0];
    [_Serial_Check_Btn setState:0];
    [_not_underbar_Btn setState:0];
    [_leave_Origin_Check setState:1];
    [_prefix_Btn setState:1];
    [_suffix_Btn setState:0];
    
    [_Digit_tw_Btn setEnabled:NO];
    [_Digit_th_Btn setEnabled:NO];
    [_Digit_fo_Btn setEnabled:NO];
    [_Digit_fi_Btn setEnabled:NO];
    [_Digit_si_Btn setEnabled:NO];
    [_Digit_se_Btn setEnabled:NO];
    [_Digit_ei_Btn setEnabled:NO];
    [_Digit_ni_Btn setEnabled:NO];
    [_Digit_te_Btn setEnabled:NO];

    prf = 0;    //連番の開始値を0で初期化
    roop = 0;   //書出しループの開始値を0で初期化
    message = @"";
    canceled = false;   //停止ボタンクリック判定　はじめは当然falsse
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [_Origin_Path setEditNotif:@"originDrag"];
    [nc addObserver:self selector:@selector(drag1:) name:@"originDrag" object:_Origin_Path];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

-(void)drag1:(NSNotification *)aNotif
{
    BOOL isDir;
    NSString *origin = _Origin_Path.stringValue;
    
    [_Output_Path setStringValue:origin];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:origin isDirectory:&isDir] && isDir)
    {
        //ドラッグされたのがフォルダだったとき
        [self allBtnOn];
    }
    else
    {
        //ドラッグされたのがファイルだったとき
        [self allBtnOff];
    }
}

- (IBAction)exChange:(id)sender
{
    oldContent = [[NSArray alloc] init];
    
    NSString *origin = _Origin_Path.stringValue;
    NSString *output = _Output_Path.stringValue;
    NSString *include = _Include_str.stringValue;
    NSString *sqValue = _number_text.stringValue;
    NSString *output_s = [NSString stringWithFormat:@"%@/",output];
    NSString *file_ext;
    
    NSFileManager *fm = [NSFileManager defaultManager];

    __block NSError *error;

    BOOL isDir;
    count = 0;
    canceled = NO;
    rename = _New_Name.stringValue;

    [_logBox setString:@""];
    
    int sqInt;
    if([sqValue isEqual:@""])
    {
        sqInt = [sqValue intValue];
    }
    else
    {
        sqInt = 0;
    }
    
    int Comp = [origin isEqualToString:output];
    
    if(![fm fileExistsAtPath:origin])
    {
        //元ファイル・フォルダのパスが存在しないとき
        AlrtMss = [self alertMessage:@"存在しないパスです" Text2:@"正しいバスを入力してください" FirstBtn:@"OK"];
        return;
    }
    else
    {
        //元ファイル・フォルダのパスが存在するとき
        if([fm fileExistsAtPath:origin isDirectory:&isDir] && isDir)
        {
            //元ファイル・フォルダのパスがフォルダだったとき
            if(![fm fileExistsAtPath:output])
            {
                //書き出し先フォルダが存在しないとき
                /*  フォルダを作るか否か  */
                AlrtMss = [self alertMessage:@"書出し先フォルダが存在しません" Text2:@"作成しますか?" FirstBtn:@"作成"];
                if(AlrtMss == NSAlertFirstButtonReturn)
                {
                    /*  フォルダを作る処理   */
                    [self mkdir:output];
                }
                else
                {
                    return;
                }
            }
            
            if([rename length] == 0)
            {
                [self alertMessage:@"変換後のファイル名が入力されていません" Text2:@"変換後のファイル名を入力してください" FirstBtn:@"OK"];
                return;
            }
            
            NSArray *dirContents = [fm contentsOfDirectoryAtPath:origin error:&error];
            NSMutableArray *file = [NSMutableArray array];
            
            int count = 0;
            
            for(int i = 0; i < dirContents.count; i++)
            {
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@",origin,dirContents[i]];
                BOOL dir;
                //NSLog(@"%@",fullPath);
                
                if(!([fm fileExistsAtPath:fullPath isDirectory:&dir] && dir))
                {
                    file[count] = dirContents[i];  //ファイルであれば別配列に格納
                    count++;   //フォルダ内のファイル数を数える
                }
            }
            
            if(count == 0)
            {
                [self alertMessage:@"フォルダ内にファイルがありません" Text2:@"正しいパスを入力してください" FirstBtn:@"OK"];
                return;
            }
            
            if(![file[0] isEqualToString:@".DS_Store"])
            {
                //file[0]がDS_Storeではなかった場合、そのままファイル名から拡張子を取得
                file_ext = [NSString stringWithFormat:@".%@",[file[0] pathExtension]];  //拡張子を取得
            }
            else
            {
                //file[0]がDS_Storeだった場合、file[1]から拡張子を取得
                file_ext = [NSString stringWithFormat:@".%@",[file[1] pathExtension]];  //拡張子を取得
            }
            
            NSMutableArray *dirFileNumber = [[NSMutableArray alloc] init];          //ファイル名の数字部分の整数値
            NSString *fileBaseName;     //ファイル名のベース部分
            int lenBaseName = 0;        //ファイル名のベース部分の長さ
            int notFoundBaseName = 1;   //ファイル名のベース部分が見つかったら0になる
            int firstFileNumber = 0;    //ファイルの連番の開始番号
            int offsetFileNumber = 0;   //ファイルの連番のオフセット値
            __block int adjustFileNumber = 0;   //offsetFileNumberを用いて算出される番号
            int ketaFileNumber = 0;     //ファイルの連番の桁数
            int j;
            
            for(int i = 0; i < count; i++)
            {
                //整数値を-1で初期化
                [dirFileNumber insertObject:[NSNumber numberWithInt:-1] atIndex:i];
            }
            
            for(int i = 0; i < count; i++)
            {
                NSString *fileName = [file[i] stringByDeletingPathExtension];
                
                if([fileName rangeOfString:include].location != NSNotFound) //もしincludeが""ならこのifは常にtrue
                {
                    //ファイル名がincludeを含む場合は、（連番用の）数字を抽出してdirFileNumberに格納
                    int len = (int)fileName.length;     //ファイル名の長さ
                    int bgnPosBaseName = 0;             //ファイル名のベース部分の開始位置
                    int endPosBaseName = len - 1;       //ファイル名のベース部分の終了位置
                    [dirFileNumber insertObject:[NSNumber numberWithInt:0] atIndex:i];
                    
                    if(('0' <= [fileName characterAtIndex:len - 1] && [fileName characterAtIndex:len - 1] <= '9')&&(_Start_Serial_Btn.state == NO))
                    {
                       // NSLog(@"in");
                        //ファイル名の末尾に数値がある
                        for(j = len - 1; j >= 0; j--)
                        {
                            if(!('0' <= [fileName characterAtIndex:j] && [fileName characterAtIndex:j] <= '9'))
                            {
                                break;
                            }
                        }
                        
                        if(j >= 0)
                        {
                            int substr = [[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))] intValue];
                            [dirFileNumber insertObject:[NSNumber numberWithInt:substr] atIndex:i];
                            if( [[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))] characterAtIndex:0] == '0')
                            {
                                int keta = (int)[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))].length;
                                if( keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        else
                        {
                            [dirFileNumber insertObject:[NSNumber numberWithInt:[fileName intValue]] atIndex:i];
                            if([fileName characterAtIndex:0] == '0')
                            {
                                int keta = (int)fileName.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                           }
                        }
                        if(notFoundBaseName == 1)
                        {
                            //ファイル名のベース部分の抽出（長さ : lenBaseName）
                            endPosBaseName = j;
                            lenBaseName = endPosBaseName - bgnPosBaseName + 1;
                            if(lenBaseName >= 1)
                            {
                                fileBaseName = [fileName substringWithRange:NSMakeRange(bgnPosBaseName, lenBaseName)];
                            }
                            notFoundBaseName = 0;
                        }
                    }
                    else if('0' <= [fileName characterAtIndex:0] && [fileName characterAtIndex:0] <= '9' )
                    {
                        //ファイル名の先頭に連番用の数字がある
                        NSLog(@"inin");
                        for(j = 0; j < len; j++)
                        {
                            if(!('0' <= [fileName characterAtIndex:j] && [fileName characterAtIndex:j] <= '9'))
                            {
                                break;
                            }
                        }
                        if( j < len)
                        {
                            int substr =  [[fileName substringWithRange:NSMakeRange(0, j)] intValue];
                            [dirFileNumber insertObject:[NSNumber numberWithInt:substr] atIndex:i];
                            NSString *srchDigit = [fileName substringWithRange:NSMakeRange(0, j)];
                            
                            if( [srchDigit characterAtIndex:0] == '0')
                            {
                                int keta = (int)srchDigit.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        else
                        {
                            [dirFileNumber insertObject:[NSNumber numberWithInt:[fileName intValue]] atIndex:i];
                            if([fileName characterAtIndex:0] == '0')
                            {
                                int keta = (int)fileName.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        
                        if(notFoundBaseName == 1)
                        {
                            //ファイル名のベース部分の抽出（長さ : lenBaseName）
                            endPosBaseName = j;
                            lenBaseName = endPosBaseName - bgnPosBaseName + 1;
                            if(lenBaseName >= 1)
                            {
                                fileBaseName = [fileName substringWithRange:NSMakeRange(bgnPosBaseName, lenBaseName)];
                            }
                            notFoundBaseName = 0;
                        }
                    }
                    else
                    {
                        NSLog(@"ininin");
                        [dirFileNumber insertObject:[NSNumber numberWithInt:0] atIndex:i];
                        if(notFoundBaseName == 1)
                        {
                            notFoundBaseName = 0;
                        }
                    }
                }
                else if([include isEqualToString:@""])
                {
                    //ファイル名がincludeを含む場合は、（連番用の）数字を抽出してdirFileNumberに格納
                    int len = (int)fileName.length;     //ファイル名の長さ
                    int bgnPosBaseName = 0;             //ファイル名のベース部分の開始位置
                    int endPosBaseName = len - 1;       //ファイル名のベース部分の終了位置
                    [dirFileNumber insertObject:[NSNumber numberWithInt:0] atIndex:i];
                    
                    if(('0' <= [fileName characterAtIndex:len - 1] && [fileName characterAtIndex:len - 1] <= '9')&&(_Start_Serial_Btn.state == NO))
                    {
                        //ファイル名の末尾に数値がある
                        for(j = len - 1; j >= 0; j--)
                        {
                            if(!('0' <= [fileName characterAtIndex:j] && [fileName characterAtIndex:j] <= '9'))
                            {
                                break;
                            }
                        }
                        
                        if(j >= 0)
                        {
                            int substr = [[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))] intValue];
                            [dirFileNumber insertObject:[NSNumber numberWithInt:substr] atIndex:i];
                            if( [[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))] characterAtIndex:0] == '0')
                            {
                                int keta = (int)[fileName substringWithRange:NSMakeRange((j + 1), (len - 1 - j))].length;
                                if( keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        else
                        {
                            [dirFileNumber insertObject:[NSNumber numberWithInt:[fileName intValue]] atIndex:i];
                            if([fileName characterAtIndex:0] == '0')
                            {
                                int keta = (int)fileName.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        if(notFoundBaseName == 1)
                        {
                            //ファイル名のベース部分の抽出（長さ : lenBaseName）
                            endPosBaseName = j;
                            lenBaseName = endPosBaseName - bgnPosBaseName + 1;
                            if(lenBaseName >= 1)
                            {
                                fileBaseName = [fileName substringWithRange:NSMakeRange(bgnPosBaseName, lenBaseName)];
                            }
                            notFoundBaseName = 0;
                        }
                    }
                    else if('0' <= [fileName characterAtIndex:0] && [fileName characterAtIndex:0] <= '9' )
                    {
                        //ファイル名の先頭に連番用の数字がある
                        NSLog(@"inin");
                        for(j = 0; j < len; j++)
                        {
                            if(!('0' <= [fileName characterAtIndex:j] && [fileName characterAtIndex:j] <= '9'))
                            {
                                break;
                            }
                        }
                        if( j < len)
                        {
                            int substr =  [[fileName substringWithRange:NSMakeRange(0, j)] intValue];
                            [dirFileNumber insertObject:[NSNumber numberWithInt:substr] atIndex:i];
                            NSString *srchDigit = [fileName substringWithRange:NSMakeRange(0, j)];
                            
                            if( [srchDigit characterAtIndex:0] == '0')
                            {
                                int keta = (int)srchDigit.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        else
                        {
                            [dirFileNumber insertObject:[NSNumber numberWithInt:[fileName intValue]] atIndex:i];
                            if([fileName characterAtIndex:0] == '0')
                            {
                                int keta = (int)fileName.length;
                                if(keta > ketaFileNumber)
                                {
                                    ketaFileNumber = keta;
                                }
                            }
                        }
                        
                        if(notFoundBaseName == 1)
                        {
                            //ファイル名のベース部分の抽出（長さ : lenBaseName）
                            endPosBaseName = j;
                            lenBaseName = endPosBaseName - bgnPosBaseName + 1;
                            if(lenBaseName >= 1)
                            {
                                fileBaseName = [fileName substringWithRange:NSMakeRange(bgnPosBaseName, lenBaseName)];
                            }
                            notFoundBaseName = 0;
                        }
                    }
                    else
                    {
                        [dirFileNumber insertObject:[NSNumber numberWithInt:0] atIndex:i];
                        if(notFoundBaseName == 1)
                        {
                            notFoundBaseName = 0;
                        }
                    }
                }
                //i番目のリストに対し、dirFileNumber[]を比べてバブルソートを実行
                //（これは[fileName rangeOfString:include].location がtrueでもfalseでも実行する）
                for(j = i; j >= 1; j--)
                {
                    if([dirFileNumber objectAtIndex:j] < [dirFileNumber objectAtIndex:(j - 1)])
                    {
                        NSString *ws = file[j];
                        file[j] = file[j - 1];
                        file[j - 1] = ws;
                        NSString *wi = dirFileNumber[j];
                        dirFileNumber[j] = dirFileNumber[j - 1];
                        dirFileNumber[j - 1] = wi;
                    }
                }
            }
            
            //ファイル名のベース部分の先頭か末尾に_か.があれば削除する
            if(lenBaseName >= 2)
            {
                NSString *fileBaseName2;
                if([fileBaseName characterAtIndex:0] == '.' || [fileBaseName characterAtIndex:0] == '_')
                {
                    fileBaseName2 = [fileBaseName substringWithRange:NSMakeRange(1, lenBaseName - 1)];
                    fileBaseName = fileBaseName2;
                }
                else if([fileBaseName characterAtIndex:(lenBaseName - 1)] == '.' || [fileBaseName characterAtIndex:(lenBaseName - 1)] == '_')
                {
                    fileBaseName2 = [fileBaseName substringWithRange:NSMakeRange(0, lenBaseName - 1)];
                    fileBaseName = fileBaseName2;
                }
            }
            //ファイルの連番の開始番号を探す
            for(int i = 0; i < count; i++)
            {
                int dfn = [[dirFileNumber objectAtIndex:i] intValue];
                if( dfn != -1)
                {
                    firstFileNumber = dfn;
                    break;
                }
            }
            //結果を確認する
            NSLog(@"Base=%@",fileBaseName);
            NSLog(@"開始番号=%d",firstFileNumber);
            NSLog(@"連番桁数=%d",ketaFileNumber);

            if([origin isEqualToString:output] && _leave_Origin_Check.state == NO)
            {
                AlrtMss = [self alertMessage:@"読み込むフォルダと書き出すフォルダが同じです。" Text2:@"現在のファイルは残りません。" FirstBtn:@"OK"];
                if(AlrtMss != NSAlertFirstButtonReturn)
                {
                    [self alertSecondMessage:@"読み込むフォルダと書き出すフォルダが同じです" Text2:@"書出し先を指定するか、元ファイルを残すに\nチェックを入れてください"];
                    return;
                }
            }
            
            if([rename isEqualToString:@""])
            {
                //変換後ファイル名の指定がなかった時の確認事項
                AlrtMss = [self alertMessage:@"新しいファイル名が入力されていません" Text2:@"現在のファイル名に連番が付加されます" FirstBtn:@"OK"];
                if(AlrtMss != NSAlertFirstButtonReturn)
                {
                    [self alertSecondMessage:@"新しいファイル名が入力されていません" Text2:@"ファイル名を入力してください"];
                    return;
                }
                rename = fileBaseName;
            }
 
            __block int noConst = 0;
            
            if(_Serial_Check_Btn.state == YES)
            {
                NSString *startSerial = _number_text.stringValue;
                prf = [startSerial intValue];
            }
            else
            {
                prf = firstFileNumber;
            }
            
            offsetFileNumber = prf - firstFileNumber;
            
            if(![output isEqualToString:origin] && _leave_Origin_Check.state == false)
            {
                    /*強制的に残すようにするか？ */
            }
            
            if([include isEqualToString:@""])
            {
                AlrtMss = [self alertMessage:@"置き換える文字列が指定されていません" Text2:@"すべてのファイルがリネームされます" FirstBtn:@"OK"];
                
                if(AlrtMss != NSAlertFirstButtonReturn)
                {
                    [self alertSecondMessage:@"置き換える文字列が指定されていません" Text2:@"置き換える文字列を入力してください"];
                    return;
                }
            }
            
            /*  ここから非同期処理   */
            dispatch_queue_t q_global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_async(q_global, ^{
                for(int i = self->roop; i < count; i++)
                {
                    if(self->canceled)
                    {
                        self->roop = i;
                        self->message = @"変換を中止しました";
                        [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                        break;
                    }
                    
                    NSString *fileName = [file[i] stringByDeletingPathExtension];
                    
                    if(![dirFileNumber[i] isEqual: @-1])
                    {
                        adjustFileNumber = offsetFileNumber + [dirFileNumber[i] intValue];
                    }
                    else
                    {
                        adjustFileNumber = 0;
                    }
                    
                    
                    if(![include isEqual:@""])
                    {
                        //以下の文字列を〜で文字列が指定されているとき
                        if([fileName rangeOfString:include].location != NSNotFound)
                        {
                            
                            if(self.Digit_Check.state == YES)
                            {
                                [self Column_Sort:adjustFileNumber];
                            }
                            else
                            {

                                NSString *prefix;
                                if(ketaFileNumber > 1)
                                {
                                    switch(ketaFileNumber)
                                    {
                                        case 2:
                                            prefix = [NSString stringWithFormat:@"%02d",adjustFileNumber];
                                            break;
                                        case 3:
                                            prefix = [NSString stringWithFormat:@"%03d",adjustFileNumber];
                                            break;
                                        case 4:
                                            prefix = [NSString stringWithFormat:@"%04d",adjustFileNumber];
                                            break;
                                        case 5:
                                            prefix = [NSString stringWithFormat:@"%05d",adjustFileNumber];
                                            break;
                                        case 6:
                                            prefix = [NSString stringWithFormat:@"%06d",adjustFileNumber];
                                            break;
                                        case 7:
                                            prefix = [NSString stringWithFormat:@"%07d",adjustFileNumber];
                                            break;
                                        case 8:
                                            prefix = [NSString stringWithFormat:@"%08d",adjustFileNumber];
                                            break;
                                        case 9:
                                            prefix = [NSString stringWithFormat:@"%09d",adjustFileNumber];
                                            break;
                                        case 10:
                                            prefix = [NSString stringWithFormat:@"%010d",adjustFileNumber];
                                            break;
                                    }
                                }
                                else
                                {
                                    prefix = [NSString stringWithFormat:@"%d", adjustFileNumber];
                                }
                                //NSLog(@"%@",prefix);
                                if(self.prefix_Btn.state == YES)
                                {
                                    if(self.not_underbar_Btn.state == YES)
                                    {
                                        self->distSerial = [NSString stringWithFormat:@"%@%@",prefix,self->rename];
                                    }
                                    else
                                    {
                                        self->distSerial = [NSString stringWithFormat:@"%@_%@",prefix,self->rename];
                                    }
                                }
                                else if(self.suffix_Btn.state == YES)
                                {
                                    if(self.not_underbar_Btn.state == YES)
                                    {
                                        self->distSerial = [NSString stringWithFormat:@"%@%@",self->rename,prefix];
                                    }
                                    else
                                    {
                                        self->distSerial = [NSString stringWithFormat:@"%@_%@",self->rename,prefix];
                                    }
                                }
                            }

                            if(![fm fileExistsAtPath:output] && (Comp != 0))
                            {
                                //書出し先フォルダが無く、ソースと書出し先が違う
                                self->AlrtMss = [self alertMessage:@"書出し先フォルダが存在しません" Text2:@"作成します" FirstBtn:@"OK"];
                                if(self->AlrtMss == NSAlertFirstButtonReturn)
                                {
                                    /*  フォルダを作る処理   */
                                    [self mkdir:output];
                                }
                                else
                                {
                                    return;
                                }
                            }
                            else if([fm fileExistsAtPath:output] && (Comp != 0))
                            {
                                //書出し先フォルダがあって、ソースと書出しが違う
                                //ここはそのまま書き出せばOK
                            }
                            else if(![fm fileExistsAtPath:output] && (Comp == 0))
                            {
                                //書出し先フォルダがなく、ソースと書出し先が同じ
                                //これはありえない
                            }
                            else if([fm fileExistsAtPath:output] && (Comp == 0))
                            {
                                //書出し先フォルダがあって、ソースと書出し先が同じ
                                //コピーしてリネーム
                            }
                            
                            //NSLog(@"distSerial = %@",distSerial);
                            //NSLog(@"fileName = %@", fileName);
                            
                            self->Old_filePath = [NSString stringWithFormat:@"%@/%@%@",origin,fileName,file_ext];
                            self->New_filePath = [NSString stringWithFormat:@"%@%@%@",output_s,self->distSerial,file_ext];

                            //[self appendText:New_filePath];
                            [self performSelectorOnMainThread:@selector(appendText:) withObject:self->New_filePath waitUntilDone:NO];
                            
                            /*  ここにスレッドをスリープさせる記述  */
                            if(self.leave_Origin_Check.state == YES)
                            {
                                //元ファイルを残す（上書きも回避）
                                if([fm fileExistsAtPath:self->New_filePath])
                                {
                                    [NSThread sleepForTimeInterval:0.3];
                                    self->message = [NSString stringWithFormat:@"......同名のファイルが既にあります\n"];
                                    [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                                }
                                else
                                {
                                    [fm copyItemAtPath:self->Old_filePath toPath:self->New_filePath error:&error];
                                    [NSThread sleepForTimeInterval:0.3];
                                    self->message = [NSString stringWithFormat:@"......完了\n"];
                                    [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                                }
                            }
                            else
                            {
                                //元ファイル残さない
                                if([fm fileExistsAtPath:self->New_filePath])
                                {
                                    [NSThread sleepForTimeInterval:0.3];
                                    self->message = [NSString stringWithFormat:@"......同名のファイルが既にあります\n"];
                                    [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                                }
                                else
                                {
                                    [fm moveItemAtPath:self->Old_filePath toPath:self->New_filePath error:&error];
                                    [NSThread sleepForTimeInterval:0.3];
                                    self->message = [NSString stringWithFormat:@"......完了\n"];
                                    [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                                }
                            }
                            [NSThread sleepForTimeInterval:0.1];
                        }
                        else
                        {
                            noConst++;
                        }
                        
                        if(noConst == count)
                        {
                            self->message = @"指定された文字列は見つかりませんでした";
                            return;
                        }
                    }
                    else
                    {
                        //以下の文字列を〜で文字列が指定されていないとき
                        if(self->_Digit_Check.state == YES)
                        {
                            [self Column_Sort:adjustFileNumber];
                        }
                        else
                        {
                            NSString *prefix;
                            if(ketaFileNumber > 1)
                            {
                                switch(ketaFileNumber)
                                {
                                    case 2:
                                        prefix = [NSString stringWithFormat:@"%02d",adjustFileNumber];
                                        break;
                                    case 3:
                                        prefix = [NSString stringWithFormat:@"%03d",adjustFileNumber];
                                        break;
                                    case 4:
                                        prefix = [NSString stringWithFormat:@"%04d",adjustFileNumber];
                                        break;
                                    case 5:
                                        prefix = [NSString stringWithFormat:@"%05d",adjustFileNumber];
                                        break;
                                    case 6:
                                        prefix = [NSString stringWithFormat:@"%06d",adjustFileNumber];
                                        break;
                                    case 7:
                                        prefix = [NSString stringWithFormat:@"%07d",adjustFileNumber];
                                        break;
                                    case 8:
                                        prefix = [NSString stringWithFormat:@"%08d",adjustFileNumber];
                                        break;
                                    case 9:
                                        prefix = [NSString stringWithFormat:@"%09d",adjustFileNumber];
                                        break;
                                    case 10:
                                        prefix = [NSString stringWithFormat:@"%010d",adjustFileNumber];
                                        break;
                                }
                            }
                            else
                            {
                                prefix = [NSString stringWithFormat:@"%d", adjustFileNumber];
                            }
                            
                            if(self->_prefix_Btn.state == YES)
                            {
                                if(self->_not_underbar_Btn.state == YES)
                                {
                                    self->distSerial = [NSString stringWithFormat:@"%@%@",prefix,self->rename];
                                }
                                else
                                {
                                    self->distSerial = [NSString stringWithFormat:@"%@_%@",prefix,self->rename];
                                }
                            }
                            else if(self->_suffix_Btn.state == YES)
                            {
                                if(self->_not_underbar_Btn.state == YES)
                                {
                                    self->distSerial = [NSString stringWithFormat:@"%@%@",self->rename,prefix];
                                }
                                else
                                {
                                    self->distSerial = [NSString stringWithFormat:@"%@_%@",self->rename,prefix];
                                }
                            }
                            if(![fm fileExistsAtPath:output] && (Comp != 0))
                            {
                                //書出し先フォルダが無く、ソースと書出し先が違う
                                self->AlrtMss = [self alertMessage:@"書出し先フォルダが存在しません" Text2:@"作成します" FirstBtn:@"OK"];
                                if(self->AlrtMss == NSAlertFirstButtonReturn)
                                {
                                    /*  フォルダを作る処理   */
                                    [self mkdir:output];
                                }
                                else
                                {
                                    return;
                                }
                            }
                            else if([fm fileExistsAtPath:output] && (Comp != 0))
                            {
                                //書出し先フォルダがあって、ソースと書出しが違う
                                //ここはそのまま書き出せばOK
                            }
                            else if(![fm fileExistsAtPath:output] && (Comp == 0))
                            {
                                //書出し先フォルダがなく、ソースと書出し先が同じ
                                //これはありえない
                            }
                            else if([fm fileExistsAtPath:output] && (Comp == 0))
                            {
                                //書出し先フォルダがあって、ソースと書出し先が同じ
                                //コピーしてリネーム
                            }
                        }
                        self->Old_filePath = [NSString stringWithFormat:@"%@/%@%@",origin,fileName,file_ext];
                        self->New_filePath = [NSString stringWithFormat:@"%@%@%@",output_s,self->distSerial,file_ext];

                        [self performSelectorOnMainThread:@selector(appendText:) withObject:self->New_filePath waitUntilDone:NO];

                        if(self->_leave_Origin_Check.state == YES)
                        {
                            //元ファイルを残す（上書きも回避）
                            if([fm fileExistsAtPath:self->New_filePath])
                            {
                                [NSThread sleepForTimeInterval:0.3];
                                self->message = [NSString stringWithFormat:@"......同名のファイルが既にあります\n"];
                                [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                            }
                            else
                            {
                                [fm copyItemAtPath:self->Old_filePath toPath:self->New_filePath error:&error];
                                [NSThread sleepForTimeInterval:0.3];
                                self->message = [NSString stringWithFormat:@"......完了\n"];
                                [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                            }
                        }
                        else
                        {
                            //元ファイル残さない
                            if([fm fileExistsAtPath:self->New_filePath])
                            {
                                [NSThread sleepForTimeInterval:0.3];
                                self->message = [NSString stringWithFormat:@"......同名のファイルが既にあります\n"];
                                [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                            }
                            else
                            {
                                [fm moveItemAtPath:self->Old_filePath toPath:self->New_filePath error:&error];
                                [NSThread sleepForTimeInterval:0.3];
                                self->message = [NSString stringWithFormat:@"......完了\n"];
                                [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                            }
                        }
                        [NSThread sleepForTimeInterval:0.1];
                        if([dirFileNumber[i] isEqual:@-1])
                        {
                            self->prf++;
                        }
                    }
                }
                if(self->canceled == NO)
                {
                    self->message = [NSString stringWithFormat:@"変換が終了しました\n"];
                    [self performSelectorOnMainThread:@selector(appendText:) withObject:self->message waitUntilDone:NO];
                }
            });
            /*ここで非同期処理終わり   */
        }
        else
        {
            //元ファイル・フォルダのパスがファイルだったとき
            AlrtMss = [self alertMessage:@"単独のファイルが選択されています" Text2:@"入力されたファイルのみが変換されます" FirstBtn:@"OK"];
            if(AlrtMss != NSAlertFirstButtonReturn)
            {
                [self alertSecondMessage:@"単独のファイルが選択されています" Text2:@"フォルダを選択してください"];
                return;
            }
            
            NSString *file = [origin lastPathComponent];
            NSString *fileExtension = [NSString stringWithFormat:@".%@",[origin pathExtension]];
            NSString *fileName = [file stringByReplacingOccurrencesOfString:fileExtension withString:@""];
            NSString *wo = [origin stringByReplacingOccurrencesOfString:file withString:@""];
            
            if((![output length] || [output isEqualToString:wo]) && _leave_Origin_Check.state == NO)
            {
                AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                if(AlrtMss != NSAlertFirstButtonReturn)
                {
                    [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                    return;
                }
            }
            
            if(![rename length])
            {
                [self alertSecondMessage:@"変換後のファイル名が入力されていません" Text2:@"変換後のファイル名を指定してください"];
                return;
            }
            
            if(![fm fileExistsAtPath:output])
            {
                AlrtMss = [self alertMessage:@"書出し先のパスが存在しません" Text2:@"フォルダを作成します" FirstBtn:@"OK"];
                if(AlrtMss != NSAlertFirstButtonReturn)
                {
                    [self mkdir:output];
                }
            }
            //NSLog(@"%@",output_s);
            
            NSString *NewPath = [NSString stringWithFormat:@"%@%@",output_s,file];
            //NSLog(@"%@",NewPath);
            
            if([NewPath isEqualToString:origin])
            {
                //書出し先のパスと元のパスが同じとき
                if(_leave_Origin_Check.state == YES)
                {
                    NewName = [NewPath stringByReplacingOccurrencesOfString:fileName withString:rename];
                    NSLog(@"%@",NewName);

                    if([fm fileExistsAtPath:NewName])
                    {
                        AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                        
                        if(AlrtMss != NSAlertFirstButtonReturn)
                        {
                            [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                            return;
                        }
                    }
                    else
                    {
                        [fm copyItemAtPath:Old_filePath toPath:New_filePath error:&error];
                    }
                }
                else
                {
                    NewName = [NewPath stringByReplacingOccurrencesOfString:fileName withString:rename];
                    if([fm fileExistsAtPath:NewName])
                    {
                        AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                        
                        if(AlrtMss != NSAlertFirstButtonReturn)
                        {
                            [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                            return;
                        }
                    }
                    else
                    {
                        [fm moveItemAtPath:Old_filePath toPath:New_filePath error:&error];
                    }
                }
            }
            else
            {
                //書出し先のパスともとのパスが違うとき
                if(_leave_Origin_Check.state == YES)
                {
                    if([fm fileExistsAtPath:NewName])
                    {
                        AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                        
                        if(AlrtMss != NSAlertFirstButtonReturn)
                        {
                            [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                            return;
                        }
                    }
                    else
                    {
                        [fm moveItemAtPath:Old_filePath toPath:New_filePath error:&error];
                    }
                }
                else
                {
                    if([fm fileExistsAtPath:NewName])
                    {
                        AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                        
                        if(AlrtMss != NSAlertFirstButtonReturn)
                        {
                            [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                            return;
                        }
                    }
                    else
                    {
                        [fm moveItemAtPath:Old_filePath toPath:New_filePath error:&error];
                    }
                }
                
                NewName = [NewPath stringByReplacingOccurrencesOfString:fileName withString:rename];
                if([fm fileExistsAtPath:NewName])
                {
                    AlrtMss = [self alertMessage:@"同じファイル名が存在しています" Text2:@"ファイルは上書きされます" FirstBtn:@"OK"];
                    
                    if(AlrtMss != NSAlertFirstButtonReturn)
                    {
                        [self alertSecondMessage:@"同じファイル名が存在しています" Text2:@"書き出し先を指定してください"];
                        return;
                    }
                }
                else
                {
                    [fm moveItemAtPath:Old_filePath toPath:New_filePath error:&error];
                }
            }
        }
    }
}

/*  停止ボタンを押したときの挙動  */
- (IBAction)Stop:(id)sender
{
    NSLog(@"Stop Click");
    canceled = YES;
}

-(void)dCheck
{
    int check;
    if(_Digit_Check.state == YES)
    {
        check = 1;
    }
    else
    {
        check = 0;
    }
    
   // return check;
}
/*  NSScrollViewにテキストを追加していく    */
-(void)appendText:(NSString *)text
{
    [_logBox.textStorage beginEditing];
    NSAttributedString *atrstr = [[NSAttributedString alloc] initWithString:text];
    [_logBox.textStorage appendAttributedString:atrstr];
    [_logBox.textStorage endEditing];
    [_logBox scrollLineDown:nil];
}

-(long int)alertMessage:(NSString *)Mess Text2:(NSString *)Info FirstBtn:(NSString *)fBtn
{
    NSAlert *alert = [[NSAlert alloc] init];
    long int result;
    
    [alert setMessageText:Mess];
    [alert setInformativeText:Info];
    [alert addButtonWithTitle:fBtn];
    [alert addButtonWithTitle:@"Cancel"];
    result = [alert runModal];
    
    return result;
}

-(void)alertSecondMessage:(NSString *)Mess Text2:(NSString *)Info
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:Mess];
    [alert setInformativeText:Info];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

-(void)Column_Sort:(int)prf
{
    NSLog(@"別関数で呼び出したprf = %d",prf);
    
    NSString *prefix;
    
    if(_Digit_tw_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%02d",prf];
    }
    else if(_Digit_th_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%03d",prf];
    }
    else if(_Digit_fo_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%04d",prf];
    }
    else if(_Digit_fi_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%05d",prf];
    }
    else if(_Digit_si_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%06d",prf];
    }
    else if(_Digit_se_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%07d",prf];
    }
    else if(_Digit_ei_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%08d",prf];
    }
    else if(_Digit_ni_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%09d",prf];
    }
    else if(_Digit_te_Btn.state == YES)
    {
        prefix = [NSString stringWithFormat:@"%010d",prf];
    }
    else
    {
        prefix = [NSString stringWithFormat:@"%d",prf];
    }
    
    if(_suffix_Btn.state == YES)
    {
        //連番を最後につける
        if(_not_underbar_Btn.state == NO)
        {
            distSerial = [NSString stringWithFormat:@"%@_%@",rename,prefix];
        }
        else
        {
            distSerial = [NSString stringWithFormat:@"%@%@",rename,prefix];
        }
    }
    else if(_prefix_Btn.state == YES)
    {
        //連番を最初につける
        if(_not_underbar_Btn.state == NO)
        {
            distSerial = [NSString stringWithFormat:@"%@_%@",prefix,rename];
        }
        else
        {
            distSerial = [NSString stringWithFormat:@"%@%@",prefix,rename];
        }
    }
   // NSLog(@"distSerial = %@",distSerial);
}

-(void) allBtnOn
{
    [_Digit_Check    setEnabled:YES];
    [_Include_str   setEnabled:YES];
    [_prefix_Btn   setEnabled:YES];
    [_suffix_Btn   setEnabled:YES];
    [_Serial_Check_Btn   setEnabled:YES];
    [_not_underbar_Btn   setEnabled:YES];
    [_Start_Serial_Btn   setEnabled:YES];
    [_number_text   setEnabled:YES];
    
    [_Digit_tw_Btn setEnabled:YES];
    [_Digit_th_Btn setEnabled:YES];
    [_Digit_fo_Btn setEnabled:YES];
    [_Digit_fi_Btn setEnabled:YES];
    [_Digit_si_Btn setEnabled:YES];
    [_Digit_se_Btn setEnabled:YES];
    [_Digit_ei_Btn setEnabled:YES];
    [_Digit_ni_Btn setEnabled:YES];
    [_Digit_te_Btn setEnabled:YES];
    
    _label1.textColor = [NSColor blackColor];
    _label2.textColor = [NSColor blackColor];
}

-(void) allBtnOff
{
    [_Digit_Check    setEnabled:NO];
    [_Include_str   setEnabled:NO];
    [_prefix_Btn   setEnabled:NO];
    [_suffix_Btn   setEnabled:NO];
    [_Serial_Check_Btn   setEnabled:NO];
    [_not_underbar_Btn   setEnabled:NO];
    [_Start_Serial_Btn   setEnabled:NO];
    [_number_text   setEnabled:NO];
    
    [_Digit_tw_Btn setEnabled:NO];
    [_Digit_th_Btn setEnabled:NO];
    [_Digit_fo_Btn setEnabled:NO];
    [_Digit_fi_Btn setEnabled:NO];
    [_Digit_si_Btn setEnabled:NO];
    [_Digit_se_Btn setEnabled:NO];
    [_Digit_ei_Btn setEnabled:NO];
    [_Digit_ni_Btn setEnabled:NO];
    [_Digit_te_Btn setEnabled:NO];
    
    _label1.textColor = [NSColor grayColor];
    _label2.textColor = [NSColor grayColor];
}

-(void)digit_allOff
{
    [_Digit_tw_Btn setState:0];
    [_Digit_th_Btn setState:0];
    [_Digit_fo_Btn setState:0];
    [_Digit_fi_Btn setState:0];
    [_Digit_si_Btn setState:0];
    [_Digit_se_Btn setState:0];
    [_Digit_ei_Btn setState:0];
    [_Digit_ni_Btn setState:0];
    [_Digit_te_Btn setState:0];
}

-(void)mkdir:(NSString *)opPath
{
    //フォルダを作成してアクセス権を777に
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm createDirectoryAtPath:opPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSTask *chmd = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    [chmd setStandardOutput:outPipe];
    
    NSPipe *errPipe = [NSPipe pipe];
    [chmd setStandardError:errPipe];
    [chmd setLaunchPath:@"/bin/chmod"];
    [chmd setArguments:[NSArray arrayWithObjects:@"-R",@"777",opPath, nil]];
    [chmd launch];
}

- (IBAction)sn_select:(id)sender
{
    /*  連番を最後に〜を選択したら連番を最初にからのチェックを外す   */
    if([_suffix_Btn intValue])
    {
        [_prefix_Btn setState:0];
    }
    else if([_prefix_Btn intValue])
    {
        [_suffix_Btn setState:0];
    }
}

- (IBAction)digit_select:(id)sender
{
    //  桁数を揃えるボタンにチェックが入っていたら桁数ボタンを有効に。
    //  チェックが入っていなければ桁数ボタンを無効に
    if(_Digit_Check.state == YES)
    {
        [self digit_allOff];

        [_Digit_tw_Btn setEnabled:YES];
        [_Digit_th_Btn setEnabled:YES];
        [_Digit_fo_Btn setEnabled:YES];
        [_Digit_fi_Btn setEnabled:YES];
        [_Digit_si_Btn setEnabled:YES];
        [_Digit_se_Btn setEnabled:YES];
        [_Digit_ei_Btn setEnabled:YES];
        [_Digit_ni_Btn setEnabled:YES];
        [_Digit_te_Btn setEnabled:YES];
    }
    else
    {
        [self digit_allOff];
        
        [_Digit_tw_Btn setEnabled:NO];
        [_Digit_th_Btn setEnabled:NO];
        [_Digit_fo_Btn setEnabled:NO];
        [_Digit_fi_Btn setEnabled:NO];
        [_Digit_si_Btn setEnabled:NO];
        [_Digit_se_Btn setEnabled:NO];
        [_Digit_ei_Btn setEnabled:NO];
        [_Digit_ni_Btn setEnabled:NO];
        [_Digit_te_Btn setEnabled:NO];
        
        [_Digit_tw_Btn setState:1];
    }
}

- (IBAction)tw_select:(id)sender
{
    //2桁ボタンにチェックを入れたら他の桁数ボタンをオフ
    if([_Digit_tw_Btn intValue])
    {
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_th_Btn intValue])
    {
        //3桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_fo_Btn intValue])
    {
        //4桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_fi_Btn intValue])
    {
        //5桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_si_Btn intValue])
    {
        //6桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_se_Btn intValue])
    {
        //7桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_se_Btn intValue])
    {
        //7桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_ei_Btn intValue])
    {
        //8桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ni_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_ni_Btn intValue])
    {
        //9桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_te_Btn setState:0];
    }
    else if([_Digit_te_Btn intValue])
    {
        //10桁ボタンにチェックを入れたら他の桁数ボタンをオフ
        [_Digit_tw_Btn setState:0];
        [_Digit_th_Btn setState:0];
        [_Digit_fo_Btn setState:0];
        [_Digit_fi_Btn setState:0];
        [_Digit_si_Btn setState:0];
        [_Digit_se_Btn setState:0];
        [_Digit_ei_Btn setState:0];
        [_Digit_ni_Btn setState:0];
    }
}

- (IBAction)fldSelectA:(id)sender
{
    NSOpenPanel *opPanel = [NSOpenPanel openPanel];
    
    [opPanel setCanChooseFiles:YES];
    [opPanel setCanChooseDirectories:YES];
    [opPanel setCanCreateDirectories:YES];
    [opPanel setPrompt:NSLocalizedString(@"選択", @"")];
    [opPanel setMessage:NSLocalizedString(@"ファイル/フォルダ選択", @"")];
    [opPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){if(result == NSModalResponseOK){ [self.Origin_Path setStringValue:opPanel.URL.path];}}];
}

- (IBAction)fldSelectB:(id)sender
{
    NSOpenPanel *opPanel = [NSOpenPanel openPanel];
    
    [opPanel setCanChooseFiles:YES];
    [opPanel setCanChooseDirectories:YES];
    [opPanel setCanCreateDirectories:YES];
    [opPanel setPrompt:NSLocalizedString(@"選択", @"")];
    [opPanel setMessage:NSLocalizedString(@"ファイル/フォルダ選択", @"")];
    [opPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){if(result == NSModalResponseOK){ [self.Output_Path setStringValue:opPanel.URL.path];}}];
}

@end
