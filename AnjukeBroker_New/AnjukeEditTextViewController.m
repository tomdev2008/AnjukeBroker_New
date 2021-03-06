//
//  AnjukeEditTextViewController.m
//  AnjukeBroker_New
//
//  Created by Wu sicong on 13-12-2.
//  Copyright (c) 2013年 Wu sicong. All rights reserved.
//

#import "AnjukeEditTextViewController.h"
#import "Util_UI.h"
#import "Util_TEXT.h"
#import <QuartzCore/QuartzCore.h>
#import "AudioToolbox/AudioToolbox.h"
#import "NSString+EmojiExtension.h"

#define APPID @"52d7a64b"
#define TIMEOUT         @"20000"            // timeout      连接超时的时间，以ms为单位

#define VOICEBACKVIEWHEIGHT 90 //语音的空间高度
#define VOICEANIMATIONIMGHEIGHT 163/2   //说话时动画图片高度
#define BUTWHID 80 //取消按钮宽度
#define BUTHIGHT 30  //
#define SOUNDBUTTONHEIGHT 57 // 键盘出来后的语音框
#define VOICEBUTTONHEIHGT 106/2 //开始语音按钮的图片高度

//#define
@interface AnjukeEditTextViewController ()
{
    float offset;
    float moveoffset;
    UIImage *corlorIMG;
    IFlySpeechRecognizer * _iFlySpeechRecognizer;
    UILabel *wordNum;
    NSString *placeHolder;
    int location; //输入框的光标位置
}
@property (nonatomic, strong) UITextView *textV;
@property (nonatomic, strong) UIImageView *backIMG;
@property (nonatomic, strong) UIImageView *beforIMG;
@property (nonatomic, strong) UIButton *stopBut;
@property (nonatomic, strong) UIButton *cancelBut;
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIButton *voiceUpBut;
@property BOOL isCanceled;
@end

@implementation AnjukeEditTextViewController
@synthesize textString;
@synthesize textFieldModifyDelegate;
@synthesize textV;
@synthesize isTitle;
@synthesize backIMG;
@synthesize beforIMG;
@synthesize stopBut;
@synthesize cancelBut;
@synthesize voiceBtn;
@synthesize voiceUpBut;
@synthesize isHZ;

#pragma mark - log
- (void)sendAppearLog {
    if (self.isHZ) {
        [self setHZAppearLog];
    }else {
        [self setAJKAppearLog];
    }
}

- (void)sendDisAppearLog {
    if (self.isHZ) {
        [self setHZDisappearLog];
    }else {
        [self setAJKDisappearLog];
        
    }
}

- (void)setHZAppearLog{
    
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_TITLE_ONVIEW page:ZF_PUBLISH_TITLE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_ONVIEW page:ZF_PUBLISH_DESCRIPTION note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }
}
- (void)setAJKAppearLog{
    
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_ONVIEW page:ESF_PUBLISH_TITLE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_DESCRIPTION_ONVIEW page:ESF_PUBLISH_DESCRIPTION note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }
}
- (void)setHZDisappearLog{
    
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:HZ_TITLE_002 page:ZF_PUBLISH_TITLE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:HZ_DESC_002 page:ZF_PUBLISH_DESCRIPTION note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"dt", nil]];
    }
}
- (void)setAJKDisappearLog{
    
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:AJK_TITLE_002 page:ESF_PUBLISH_TITLE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:AJK_DESC_002 page:ESF_PUBLISH_DESCRIPTION note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"dt", nil]];
    }
}
#pragma mark - InputLog
- (void)setHZInputLog {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_TITLE_SPEAK page:ZF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_SPEAK page:ZF_PUBLISH_DESCRIPTION note:nil];
    }
}
- (void)setAJKInputLog {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_SPEAK page:ESF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_DESCRIPTION_SPEAK page:ESF_PUBLISH_DESCRIPTION note:nil];
    }
}
#pragma mark - RightButtonLog
- (void)rightButtonHZLog {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_TITLE_SAVE page:ZF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_SAVE page:ZF_PUBLISH_DESCRIPTION note:nil];
    }
}
- (void)rightButtonAJKLog {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_SAVE page:ESF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_DESCRIPTION_SAVE page:ESF_PUBLISH_DESCRIPTION note:nil];
    }
}
#pragma mark - FlyInputLog
- (void)setHZFlyInput {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_TITLE_SPEAK page:ZF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_SPEAK page:ZF_PUBLISH_DESCRIPTION note:nil];
    }
}
- (void)setAJKInput {
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_SPEAK page:ESF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_DESCRIPTION_SPEAK page:ESF_PUBLISH_DESCRIPTION note:nil];
    }
    
}

#pragma mark - BackButtonLog
- (void)setHZBackLog{
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_TITLE_BACK page:ZF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_BACK page:ZF_PUBLISH_DESCRIPTION note:nil];
    }
    
}
- (void)setAJKBackLog{
    if (self.isTitle) {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_BACK page:ESF_PUBLISH_TITLE note:nil];
    }else {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_DESCRIPTION_BACK page:ESF_PUBLISH_DESCRIPTION note:nil];
    }
    
}

#pragma mark - View lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.isCanceled = YES;
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
	// Do any additional setup after loading the view.
    
//    [self addRightButton:@"完成" andPossibleTitle:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //    [self.textV becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_iFlySpeechRecognizer stopListening];
    _iFlySpeechRecognizer.delegate = nil;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setWordNumText];
}
#pragma mark - private method
- (void)initModel {
    location = 0;
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@,timeout=%@",APPID,TIMEOUT];
    _iFlySpeechRecognizer = [IFlySpeechRecognizer createRecognizer: initString delegate:self];
    _iFlySpeechRecognizer.delegate = self;
    [_iFlySpeechRecognizer setParameter:@"domain" value:@"sms"];
    [_iFlySpeechRecognizer setParameter:@"sample_rate" value:@"16000"];
    [_iFlySpeechRecognizer setParameter:@"plain_result" value:@"0"];
    
}

- (void)dealloc {
    [_iFlySpeechRecognizer stopListening];
    _iFlySpeechRecognizer.delegate = nil;
    self.textFieldModifyDelegate = nil;
}
- (void)initDisplay {
    wordNum = [[UILabel alloc] initWithFrame:CGRectZero];
    wordNum.backgroundColor = [UIColor clearColor];
    [self.view addSubview:wordNum];
    if(self.isTitle){
        //        wordNum.text = @"30";
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
        //        [self setWordNumText];
    } else {
        wordNum.frame = CGRectZero;
    }
    
    self.voiceUpBut = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceUpBut.frame = CGRectMake(0, 0, 0, 0);
    [self.voiceUpBut setTitle:@"语音输入" forState:UIControlStateNormal];
    [self.voiceUpBut setImage:[UIImage imageNamed:@"anjuke_icon_sound_button.png"] forState:UIControlStateNormal];
    [self.voiceUpBut setImage:[UIImage imageNamed:@"anjuke_icon_sound_button1.png"] forState:UIControlStateHighlighted];
    [self.voiceUpBut addTarget:self action:@selector(startAgain) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.voiceUpBut];
    
    
    self.voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceBtn.frame = CGRectMake(160 - 106/2/2, [self windowHeight] - 106/2 - 64 - 15 , 106/2, 106/2);
    [self.voiceBtn setImage:[UIImage imageNamed:@"anjuke_icon_sound.png"] forState:UIControlStateNormal];
    [self.voiceBtn setImage:[UIImage imageNamed:@"anjuke_icon_sound1.png"] forState:UIControlStateHighlighted];
    [self.voiceBtn addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
    //    [voiceBack addSubview:voiceBtn];
    [self.view addSubview:self.voiceBtn];
    
    self.cancelBut = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelBut setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBut setTitleColor:[Util_UI colorWithHexString:@"FF8800"] forState:UIControlStateNormal];
    self.cancelBut.frame = CGRectZero;
    [self.cancelBut addTarget:self action:@selector(canceled:) forControlEvents:UIControlEventTouchDown];
    //    [voiceBack addSubview:voiceBtn];
    [self.view addSubview:self.cancelBut];
    
    self.stopBut = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stopBut setTitle:@"说完了" forState:UIControlStateNormal];
    [self.stopBut setTitleColor:[Util_UI colorWithHexString:@"FF8800"] forState:UIControlStateNormal];
    self.stopBut.frame = CGRectZero;
    [self.stopBut addTarget:self action:@selector(canceled:) forControlEvents:UIControlEventTouchDown];
    //    [voiceBack addSubview:voiceBtn];
    [self.view addSubview:self.stopBut];
    
    UIImage *orgIMG = [UIImage imageNamed:@"anjuke_icon_saying.png"];
    CGRect rect = CGRectMake(0, 0, 163, 60);
    CGImageRef imageRef=CGImageCreateWithImageInRect([orgIMG CGImage],rect);
    corlorIMG=[UIImage imageWithCGImage:imageRef];
    
    self.backIMG = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.backIMG.image = [UIImage imageNamed:@"anjuke_icon_saying1.png"];
    [self.view addSubview:self.backIMG];
    
    self.beforIMG = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.beforIMG.image = corlorIMG;
    [self.view addSubview:self.beforIMG];
    
}

- (void)setTextFieldDetail:(NSString *)string {
    CGFloat TextViewH = 260;
    if ([self windowHeight] <= 960/2) {
        TextViewH = 180;
    }
    
    UITextView *cellTextField = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBACKVIEWHEIGHT - 64)];
    cellTextField.backgroundColor = [UIColor clearColor];
    cellTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if(self.isTitle){
        placeHolder = [[NSString alloc] initWithFormat:@"简单明了地说出房源的特色，至少5个字"];
    } else {
        placeHolder = [[NSString alloc] initWithFormat:@"说说小区周边生活配套、小区内部环境、房源内部装修的房源描述，至少10个字"];
    }
    cellTextField.text = placeHolder;
    cellTextField.delegate = self;
    cellTextField.font = [UIFont systemFontOfSize:17];
    cellTextField.secureTextEntry = NO;
    cellTextField.textColor = [Util_UI colorWithHexString:@"#999999"];
    cellTextField.layer.borderWidth = 1;
    cellTextField.layer.borderColor = [[Util_UI colorWithHexString:@"CCCCCC"] CGColor];
    cellTextField.layer.cornerRadius = 6;
    self.textV = cellTextField;
    [self.view addSubview:cellTextField];
    if(self.isTitle){
        cellTextField.returnKeyType = UIReturnKeyDone;
    } else {
        cellTextField.returnKeyType = UIReturnKeyDefault;
    }
    
    if(self.textV && [string length] > 0){
        self.textV.text = string;
        self.textV.textColor = SYSTEM_BLACK;
    }
    //    [self setWordNumText];
}

- (void)setWordNumText {
    if (!self.isTitle) {
        return;
    }
    if (self.textV && [self.textV.text length]>0 && ![self.textV.text isEqualToString:placeHolder]) {
        wordNum.text = [NSString stringWithFormat:@"%d", 30 - self.textV.text.length];
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.text = @"30";
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    }
    
}

- (void)doBack:(id)sender {
    if (self.isHZ) {
        [self setHZBackLog];
    }else {
        [self setAJKBackLog];
    }
    if (!self.textV || [self.textV.text isEqualToString:placeHolder]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if ([[Util_TEXT rmBlankFromString:self.textV.text] isEqualToString:@""]) {
        if (self.textFieldModifyDelegate && [self.textFieldModifyDelegate respondsToSelector:@selector(textDidInput:isTitle:)]) {
            if ([self.textV.text isEqualToString:placeHolder]) {
                [self.textFieldModifyDelegate textDidInput:@"" isTitle:self.isTitle];
            }else{
                [self.textFieldModifyDelegate textDidInput:self.textV.text isTitle:self.isTitle];
            }
        }
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self rightButtonAction:self];
//    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提醒"
//                                                 message:@"是否保存当前输入"
//                                                delegate:self
//                                       cancelButtonTitle:nil
//                                       otherButtonTitles:@"不保存",@"保存并退出",nil];
//    av.tag = 102;
//    [av show];
}

- (void)rightButtonAction:(id)sender {
    self.textV.text = [self.textV.text removeEmoji];
//    if (self.isHZ) {
//        [self rightButtonHZLog];
//    }else {
//        [self rightButtonAJKLog];
//    }
    if (self.isTitle) {
        if (self.textV.text.length > 30 || self.textV.text.length < 5 || [self.textV.text isEqualToString:placeHolder]) {
            [self showInfo:@"房源标题必须5到30个字符"];
            return;
        }
    }
    else {
        if (self.textV.text.length < 10 || [self.textV.text isEqualToString:placeHolder]) {
            [self showInfo:@"房源描述必须至少10个字符"];
            return;
        }
    }
    
    if (self.textFieldModifyDelegate && [self.textFieldModifyDelegate respondsToSelector:@selector(textDidInput:isTitle:)]) {
        if ([self.textV.text isEqualToString:placeHolder]) {
            [self.textFieldModifyDelegate textDidInput:@"" isTitle:self.isTitle];
        }else{
            [self.textFieldModifyDelegate textDidInput:self.textV.text isTitle:self.isTitle];
        }
    }
    [self.textV resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Text Field Delegate

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [self setLocationBySelectedRange];
    if (isHZ)
    {
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_PUBLISH_DESCRIPTION_WORDS page:ZF_PUBLISH_DESCRIPTION note:nil];
    }else
    {
        [[BrokerLogger sharedInstance] logWithActionCode:ESF_PUBLISH_TITLE_WORDS page:ESF_PUBLISH_TITLE note:nil];
    }
    
    //    location =self.textV.selectedRange.location;
    [textView resignFirstResponder];
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self setLocationBySelectedRange];
    //    location = self.textV.selectedRange.location;
    if ([self.textV.text isEqualToString:placeHolder]) {
        self.textV.text = @"";
        self.textV.textColor = SYSTEM_BLACK;
    }
    //    if (self.textV.text.intValue < 1 && range.length == 0)
    
    
    if (self.isTitle && [text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    if(self.isTitle){
        NSString *temp = [textView.text stringByReplacingCharactersInRange:range withString:text];
        if ([temp isEqualToString:placeHolder]) {
            wordNum.text = [NSString stringWithFormat:@"30"];
            return YES;
        }
        if (temp.length > 30) {
            DLog(@"111222 %@======%d", temp, [temp length]);
            self.textV.text = [temp substringToIndex:30];
            return NO;
        }else {
            wordNum.text = [NSString stringWithFormat:@"%d", 30 - [temp length]];
        }
    }
    
    return YES;
}
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.isHZ) {
        [self setHZInputLog];
    }else {
        [self setAJKInputLog];
    }
    
    [self setLocationBySelectedRange];
    if ([self.textV.text isEqualToString:placeHolder]) {
        self.textV.text = @"";
        self.textV.textColor = SYSTEM_BLACK;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self setLocationBySelectedRange];
    //    location =self.textV.selectedRange.location;
    if(self.isTitle){
        NSString *temp = self.textV.text;
        [self setWordNumValue:temp];
    }
    
    //textView.text = [textView.text substringToIndex:2];
}

- (void)setWordNumValue:(NSString *) temp {
    
    if ([temp isEqualToString:placeHolder]) {
        wordNum.text = [NSString stringWithFormat:@"30"];
        wordNum.textColor = SYSTEM_BLACK;
        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
        return;
    }
    
    NSInteger num = [temp length];
    if(num < 30){
        wordNum.text = [NSString stringWithFormat:@"%d", 30 - [temp length]];
        wordNum.textColor = SYSTEM_BLACK;
        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    }else if (num == 30) {
        wordNum.textColor = [UIColor redColor];
        wordNum.text = [NSString stringWithFormat:@"%d", 30 - [temp length]];
        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.textColor = [UIColor redColor];
        wordNum.text = [NSString stringWithFormat:@"超出：%d字", num - 30];
        wordNum.frame = CGRectMake(self.textV.frame.size.width - 110, self.textV.frame.size.height - 40, 100, 30);
    }
    
    
    //    self.textV.text = temp;
}

#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: //不保存
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
            break;
            
        case 1: //保存并退出
        {
            [self rightButtonAction:self];
        }
            break;
        default:
            break;
    }
}

#pragma mark - keyBoardNotification
- (void)keyboardWillShow:(NSNotification *)notification

{
    [self cancelSpeech];
    [self cancelFrameChange];
    [self setLocationBySelectedRange];
    //    location = self.textV.selectedRange.location;
    //static CGFloat normalKeyboardHeight = 216.0f;
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    offset = kbSize.height;
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - SOUNDBUTTONHEIGHT - 64 - offset);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    self.voiceUpBut.frame = CGRectMake((320 - 100)/2, [self windowHeight] - offset - 64 - 10 - 53/2, 200/2, 53/2);
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    offset = kbSize.height;
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - SOUNDBUTTONHEIGHT - 64 - offset);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    self.voiceUpBut.frame = CGRectMake((320 - 200)/2, [self windowHeight] - offset - 64 - 10, 200/2, 53/2);
}

- (void)keyboardWillHide:(NSNotification *)notification{
    
    [self dealwithHideKeyboard];
    
}

-(void)dealwithHideKeyboard{
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBACKVIEWHEIGHT - 64);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    self.voiceUpBut.frame = CGRectZero;
}

#pragma mark - methods about listening

/** 停止录音
 
 调用此函数会停止录音，并开始进行语音识别
 */
-(void)stopSpeech {
    [_iFlySpeechRecognizer stopListening];
    _iFlySpeechRecognizer.delegate = nil;
}
/** 开始识别
 
 同时只能进行一路会话,这次会话没有结束不能进行下一路会话，否则会报错
 */
-(void)startSpeech {
    if (self.isHZ) {
        [self setHZDisappearLog];
    }else {
        [self setAJKDisappearLog];
        
    }
    _iFlySpeechRecognizer.delegate = self;
    [_iFlySpeechRecognizer startListening];
}

/** 取消本次会话 */
-(void)cancelSpeech {
    
    [_iFlySpeechRecognizer cancel];
    _iFlySpeechRecognizer.delegate = nil;
}

#pragma mark - IFlySpeechRecognizerDelegate
/**
 * @fn      onVolumeChanged
 * @brief   音量变化回调
 *
 * @param   volume      -[in] 录音的音量，音量范围1~100
 * @see
 */
- (void) onVolumeChanged: (int)volume
{
    if (self.isCanceled) {
        return;
    }
    DLog(@"==========>>>>>>>>>%d",volume);
    [self speechAnimation:volume];
}

/**
 * @fn      onBeginOfSpeech
 * @brief   开始识别回调
 *
 * @see
 */
- (void) onBeginOfSpeech
{
    [self playAudioVoice];
}

/**
 * @fn      onEndOfSpeech
 * @brief   停止录音回调(自动停止时回调)
 *
 * @see
 */
- (void) onEndOfSpeech
{
    _iFlySpeechRecognizer.delegate = nil;
    [self cancelFrameChange];
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBUTTONHEIHGT - 64 - 15*2 - 10);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    [self playAudioVoice];
}


/**
 * @fn      onError
 * @brief   识别结束回调
 *
 * @param   errorCode   -[out] 错误类，具体用法见IFlySpeechError
 */
- (void) onError:(IFlySpeechError *) error
{
    _iFlySpeechRecognizer.delegate = nil;
    [self cancelFrameChange];
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBUTTONHEIHGT - 64 - 15*2 - 10);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //            wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    
}

/** 取消识别回调
 
 当调用了`cancel`函数之后，会回调此函数，在调用了cancel函数和回调onError之前会有一个短暂时间，您可以在此函数中实现对这段时间的界面显示。
 */
- (void) onCancel {
    [self cancelFrameChange];
    _iFlySpeechRecognizer.delegate = self;
}
/**
 * @fn      onResults
 * @brief   识别结果回调
 *
 * @param   result      -[out] 识别结果，NSArray的第一个元素为NSDictionary，NSDictionary的key为识别结果，value为置信度
 * @see
 */

- (void) onResults:(NSArray *) results
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [results objectAtIndex:0];
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    DLog(@"转写结果：%@",result);
    if ([self.textV.text isEqualToString:placeHolder]) {
        self.textV.text = @"";
        self.textV.textColor = SYSTEM_BLACK;
    }
    NSString *temp=[NSString stringWithFormat:@"%@%@", self.textV.text, result];
    if(self.isTitle)
        [self setWordNumValue:temp];
    NSString *content = self.textV.text;
    if (content.length < location ) {
        return;
    }
    NSString *resultStr = [NSString stringWithFormat:@"%@%@%@",[content substringToIndex:location], result, [content substringFromIndex:location]];
    DLog(@"===============================================%d", location);
    self.textV.text = resultStr;
    location = location + result.length;
}

#pragma mark - privateMethod
- (void)start:(id) sender {
    self.isCanceled = NO;
    //    self.beforIMG = [[UIImageView alloc] initWithFrame:CGRectMake(voiceBtn.frame.origin.x - 25, voiceBtn.frame.origin.y - 25, 82, 30)];
    //    self.backIMG = [[UIImageView alloc] initWithFrame:CGRectMake(voiceBtn.frame.origin.x - 25, voiceBtn.frame.origin.y - 25, 82, 82)];
    //    [self startSpeech];
    [self playAudioVoice];
    //    [self perfo]
    [self performSelector:@selector(delayStartSpeech) withObject:Nil afterDelay:1.0f];
    [self speechAnimation:0];
    self.voiceBtn.frame = CGRectZero;
    self.cancelBut.frame = CGRectMake(20, [self windowHeight] - 15 - VOICEANIMATIONIMGHEIGHT/2 - BUTHIGHT/2 - 64, BUTWHID, BUTHIGHT);
    self.stopBut.frame = CGRectMake([self windowWidth] - 20 - BUTWHID, [self windowHeight] - 15 - VOICEANIMATIONIMGHEIGHT/2 - BUTHIGHT/2 - 64, BUTWHID, BUTHIGHT);
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEANIMATIONIMGHEIGHT - 64 - 15*2 - 10);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    
}

- (void)speechAnimation:(int) volume {
    UIImage *orgIMG = [UIImage imageNamed:@"anjuke_icon_saying.png"];
    CGRect rect = CGRectMake(0, 0, 163, 163 - 163 * volume/30 - 20);
    CGImageRef imageRef=CGImageCreateWithImageInRect([orgIMG CGImage],rect);
    corlorIMG=[UIImage imageWithCGImage:imageRef];
    self.backIMG.frame = CGRectMake((320 - VOICEANIMATIONIMGHEIGHT)/2 , [self windowHeight] - 106/2 - 64 - 15 - 25, 82, 82);
    self.backIMG.image = [UIImage imageNamed:@"anjuke_icon_saying1.png"];
    self.beforIMG.frame = CGRectMake((320 - VOICEANIMATIONIMGHEIGHT)/2, [self windowHeight] - 106/2 - 64 - 15 - 25, 82, 82 - 163 * volume/30/2 - 10);
    self.beforIMG.image = corlorIMG;
}

- (void)canceled:(id) sender {
    self.isCanceled = YES;
    [self playAudioVoice];
    [self stopSpeech];
    [self cancelFrameChange];
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBACKVIEWHEIGHT - 64);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
}

- (void)cancelFrameChange{
    self.cancelBut.frame = CGRectZero;
    self.stopBut.frame = CGRectZero;
    self.backIMG.frame = CGRectZero;
    self.beforIMG.frame = CGRectZero;
    //    self.voiceBtn.frame = CGRectMake(160 - 106/2/2, self.textV.frame.size.height + self.textV.frame.origin.y +15, 106/2, 106/2);
    self.voiceBtn.frame = CGRectMake(160 - 106/2/2, [self windowHeight] - 106/2 - 64 - 15 , 106/2, 106/2);
    
}

- (void)startAgain {
    self.isCanceled = NO;
    self.voiceUpBut.frame = CGRectZero;
    [self.textV resignFirstResponder];
    [self start:nil];
}

- (void)speechOver:(id)sender {
    [self stopSpeech];
    [self cancelFrameChange];
    self.textV.frame = CGRectMake(10, 10, [self windowWidth] - 20, [self windowHeight] - VOICEBACKVIEWHEIGHT - 64 - 15*2 - 10);
    if(self.isTitle){
        [self setWordNumValue:self.textV.text];
        //        wordNum.frame = CGRectMake(self.textV.frame.size.width - 40, self.textV.frame.size.height - 40, 30, 30);
    } else {
        wordNum.frame = CGRectZero;
    }
    
}
- (void)playAudioVoice {
    static SystemSoundID soundIDTest = 0;
    NSString * path = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"mp3"];
    if (path) {
        AudioServicesCreateSystemSoundID( (__bridge CFURLRef)[NSURL fileURLWithPath:path], &soundIDTest );
    }
    AudioServicesPlaySystemSound(soundIDTest );
    
}

- (void)delayStartSpeech{
    [self performSelectorOnMainThread:@selector(startSpeech) withObject:nil waitUntilDone:NO];
    
}
- (void)setLocationBySelectedRange {
    location = self.textV.selectedRange.location;
}

@end
