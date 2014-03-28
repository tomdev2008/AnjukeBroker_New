//
//  ViewController.m
//  X
//
//  Created by 杨 志豪 on 2/12/14.
//  Copyright (c) 2014 williamYang. All rights reserved.
//

#import "AXChatViewController.h"

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <OHAttributedLabel/NSAttributedString+Attributes.h>
#import <OHAttributedLabel/OHASBasicMarkupParser.h>

// Cell
#import "AXChatMessageRoomSourceCell.h"
#import "AXChatMessageImageCell.h"
#import "AXChatMessagePublicCardCell.h"
#import "AXChatMessageTextCell.h"
#import "AXChatMessageSystemTimeCell.h"
#import "AXPhoto.h"

#import "NSString+AXChatMessage.h"
#import "UIColor+AXChatMessage.h"
#import "NSString+JSMessagesView.h"

#import "AXChatMessageCenter.h"

#import "AXPullToRefreshContentView.h"
#import "JSMessageInputView.h"

// Controller
#import "AXChatWebViewController.h"
#import "MapViewController.h"
#import "AXPhotoBrowser.h"

#import "AXPhotoManager.h"
#import "AXCellFactory.h"
#import "AXChatContentValidator.h"


//录音组件
#import "KKAudioComponent.h"


//输入框和发送按钮栏的高度
static CGFloat const AXInputBackViewHeight = 49;
//键盘高度
static CGFloat const AXMoreBackViewHeight = 217.0f;

#ifdef DEBUG
static NSInteger const AXMessagePageSize = 15;
#else
static NSInteger const AXMessagePageSize = 15;
#endif
static CGFloat const AXScrollContentOffsetY = 800;

static NSString * const AXChatJsonVersion = @"1";

static NSString * const SpeekImgNameKeyboard = @"anjuke_icon_keyboard.png";
static NSString * const SpeekImgNameKeyboardHighlight = @"anjuke_icon_keyboard1.png";

static NSString * const SpeekImgNameVoice = @"anjuke_icon_voice.png";
static NSString * const SpeekImgNameVoiceHighlight  = @"anjuke_icon_voice1.png";

@interface AXChatViewController ()<UITableViewDelegate, UITableViewDataSource, OHAttributedLabelDelegate, AXPullToRefreshViewDelegate, UIAlertViewDelegate, AXChatBaseCellDelegate, JSDismissiveTextViewDelegate, MapViewControllerDelegate>

@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, strong) UITableViewCell *selectedCell;
@property (nonatomic) BOOL isMenuVisible;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) CGFloat tableViewBottom;
@property (nonatomic) BOOL hasMore;

@property (nonatomic, strong) AXPullToRefreshView *pullToRefreshView;
@property (nonatomic, strong) AXMappedMessage *lastMessage;
@property (nonatomic, strong) UILabel *sendLabel;
@property (nonatomic, strong) UIControl *keyboardControl;
@property (nonatomic, strong) AXChatContentValidator *contentValidator;
@property (nonatomic, copy) NSString *playingIdentifier;

@property (nonatomic, strong) AXMappedPerson *currentPerson;


// JSMessage
@property (nonatomic, strong) UIView *inputBackView;
@property (nonatomic) CGFloat previousTextViewContentHeight;
@property (nonatomic) BOOL isUserScrolling;
@property (nonatomic, strong) JSMessageInputView *messageInputView;

//Debug
@property (nonatomic, strong) NSString *testUid;
@property (nonatomic, strong) NSNotification *preNotification;


//录音相关
@property (nonatomic, retain) UIImageView* volumnImageView;
@property (nonatomic, retain) MBProgressHUD* hud;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic, strong) UIButton *pressSpeek;
@property BOOL isVoiceInput;
@property (nonatomic, retain) UIImageView* warningImageView;
@property (nonatomic, retain) UIImageView* microphoneImageView;
@property (nonatomic, retain) UIImageView* highlightedMicrophoneImageView;
@property (nonatomic, retain) UIImageView* backgroundImageView;
@property (nonatomic, retain) UIImageView* dustbinImageView;
@property (nonatomic, retain) UIImageView* cancelBackgroundImgaeView;
@property (nonatomic, retain) NSDate* date;
@property (nonatomic, retain) UILabel* hudLabel;
@property (nonatomic, retain) UILabel* countDownLabel;
@property (nonatomic, retain) UIImage* corlorIMG;
@property (nonatomic, assign) CGFloat curCount;
@property (nonatomic, assign) BOOL isInterrupted;
@property (nonatomic, assign) BOOL playTipView;
#define MAX_RECORD_TIME 60

@end

@implementation AXChatViewController
@synthesize myTableView;

#pragma mark - lifeCyle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.isBroker = YES;
        _isMenuVisible = YES;
        _isFinished = NO;
        _needSendProp = NO;
        _hasMore = NO;
        self.isVoiceInput = NO;
        _contentValidator = [[AXChatContentValidator alloc] init];
        _playingIdentifier = @"";
    }
    return self;
}

- (void)dealloc
{
    DLog(@"AXChatViewController dealloc");
    [self.messageInputView.textView removeObserver:self forKeyPath:@"contentSize"];
    self.messageInputView = nil;
    self.pullToRefreshView.delegate = nil;
    self.pullToRefreshView = nil;
    self.myTableView.delegate = nil;
    self.myTableView.dataSource = nil;
    self.myTableView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.isFinished) {
        self.currentPerson = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson];
    }
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboardNotification:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboardNotification:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.isFinished) {
        self.isFinished = YES;
        if (self.conversationListItem) {
            if (!self.previousTextViewContentHeight) {
                self.previousTextViewContentHeight = self.messageInputView.textView.contentSize.height;
            }
            self.messageInputView.textView.text = self.conversationListItem.draftContent;
        }
        [self scrollToBottomAnimated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //草稿
    if (self.messageInputView) {
        [[AXChatMessageCenter defaultMessageCenter] saveDraft:self.messageInputView.textView.text friendUID:[self checkFriendUid]];
    }

    [self.messageInputView resignFirstResponder];
    [self setEditing:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO animated:YES];

    [[AXChatMessageCenter defaultMessageCenter] didLeaveChattingList];
    [self cancelKKAudioPlaying];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // init Data
    [self initData];
    
    // init UI
    [self initUI];
    [self fetchLastChatList];
    [self initBlock];
    [self initPullToRefresh];
    
}

- (void)initData {
    self.conversationListItem = [[AXChatMessageCenter defaultMessageCenter] fetchConversationListItemWithFriendUID:[self checkFriendUid]];
    self.currentPerson = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson];
    self.friendPerson = [[AXChatMessageCenter defaultMessageCenter] fetchPersonWithUID:[self checkFriendUid]];
    self.cellDict = [NSMutableDictionary dictionary];
    self.identifierData = [NSMutableArray array];
}

#pragma mark - Private Method

- (void)initUI {
    if (self.brokerName) {
        self.title = self.brokerName;
    } else {
        self.title = self.friendPerson.name;
    }
    [self.view setBackgroundColor:[UIColor axChatBGColor:self.isBroker]];
    
    NSInteger viewHeight = 20;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        viewHeight = 0;
    }
    
    self.myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, AXWINDOWWHIDTH, AXWINDOWHEIGHT - AXInputBackViewHeight - viewHeight) style:UITableViewStylePlain];
    self.myTableView.delegate = self;
    self.myTableView.dataSource = self;
    self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.myTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.myTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.myTableView];
    
    self.keyboardControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, self.myTableView.width, 10)];
    self.keyboardControl.backgroundColor = [UIColor clearColor];
    [self.keyboardControl addTarget:self action:@selector(didClickKeyboardControl) forControlEvents:UIControlEventTouchUpInside];
    self.keyboardControl.hidden = YES;
    [self.view addSubview:self.keyboardControl];
    
    
    self.moreBackView = [[UIView alloc] init];
    self.moreBackView.frame = CGRectMake(0, AXWINDOWHEIGHT - AXNavBarHeight - AXStatuBarHeight - AXMoreBackViewHeight, AXWINDOWWHIDTH, AXMoreBackViewHeight);
    self.moreBackView.backgroundColor = [UIColor axChatBGColor:self.isBroker];
    self.moreBackView.hidden = YES;
    [self.view addSubview:self.moreBackView];
    
    CGSize size = self.view.frame.size;
    CGFloat inputViewHeight = 49;
    UIPanGestureRecognizer *pan = self.myTableView.panGestureRecognizer;
    CGRect inputFrame = CGRectMake(0.0f,
                                   size.height - inputViewHeight,
                                   size.width,
                                   inputViewHeight);
    
    JSMessageInputView *inputView = [[JSMessageInputView alloc] initWithFrame:inputFrame
                                                                        style:JSMessageInputViewStyleFlat
                                                                     delegate:self
                                                         panGestureRecognizer:pan isBroker:self.isBroker];
    [self.view addSubview:inputView];
    self.messageInputView = inputView;
    [self.messageInputView.textView addObserver:self
                                     forKeyPath:@"contentSize"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
    CGRect textViewRect = self.messageInputView.textView.frame;
    if (!self.isBroker) {
        inputView.sendButton.enabled = NO;
        [inputView.sendButton addTarget:self
                                 action:@selector(sendPressed:)
                       forControlEvents:UIControlEventTouchUpInside];
    } else {
        
        
        self.messageInputView.textView.frame = CGRectMake(textViewRect.origin.x + 40, textViewRect.origin.y, textViewRect.size.width - 40, textViewRect.size.height);
        self.sendBut = [UIButton buttonWithType:UIButtonTypeCustom];
        self.sendBut.frame = CGRectMake(270.0f + 4.0f, 2.0f, 45.0f, 45.0f);
        [self.sendBut addTarget:self action:@selector(didMoreBackView:) forControlEvents:UIControlEventTouchUpInside];
        [self.sendBut setBackgroundImage:[UIImage imageNamed:@"anjuke_icon_add_more.png"] forState:UIControlStateNormal];
        [self.sendBut setBackgroundImage:[UIImage imageNamed:@"anjuke_icon_add_more_selected.png"] forState:UIControlStateHighlighted];
        [self.messageInputView addSubview:self.sendBut];
        
        self.voiceBut = [UIButton buttonWithType:UIButtonTypeCustom];
        self.voiceBut.frame = CGRectMake(2.0f + 4.0f, 2.0f, 45.0f, 45.0f);
        [self.voiceBut addTarget:self action:@selector(speeking) forControlEvents:UIControlEventTouchDown];
        [self.voiceBut setImage:[UIImage imageNamed:SpeekImgNameVoice] forState:UIControlStateNormal];
        [self.voiceBut setImage:[UIImage imageNamed:SpeekImgNameVoiceHighlight] forState:UIControlStateHighlighted];
        [self.messageInputView addSubview:self.voiceBut];
        
        self.pressSpeek = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.pressSpeek addTarget:self action:@selector(didClickRecored:) forControlEvents:UIControlEventTouchDown];
        [self.pressSpeek addTarget:self action:@selector(didCommitVoice) forControlEvents:UIControlEventTouchUpInside];
        [self.pressSpeek addTarget:self action:@selector(didCancelVoice) forControlEvents:UIControlEventTouchUpOutside];
        [self.pressSpeek addTarget:self action:@selector(continueRecordVoice) forControlEvents:UIControlEventTouchDragEnter];
        [self.pressSpeek addTarget:self action:@selector(willCancelVoice) forControlEvents:UIControlEventTouchDragExit];
        
        
        self.pressSpeek.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.pressSpeek setTitle:@"按住说话" forState:UIControlStateNormal];
        [self.pressSpeek setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.pressSpeek setTitle:@"松开结束" forState:UIControlStateHighlighted];
        [self.pressSpeek setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [self.pressSpeek setTitle:@"松开结束" forState:UIControlStateSelected];
        [self.pressSpeek setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        UIImage* imageNormal = [UIImage imageNamed:@"anjuke_icon_input_voice"];
        imageNormal = [imageNormal stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        UIImage* imageHighlighted = [UIImage imageNamed:@"anjuke_icon_input_voice_press"];
        imageHighlighted = [imageHighlighted stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        
        [self.pressSpeek setBackgroundImage:imageNormal forState:UIControlStateNormal];
        [self.pressSpeek setBackgroundImage:imageHighlighted forState:UIControlStateHighlighted];
        [self.pressSpeek setBackgroundImage:imageHighlighted forState:UIControlStateSelected];
        
        [self.messageInputView addSubview:self.pressSpeek];
    }
    
    UIButton *pickIMG = [UIButton buttonWithType:UIButtonTypeCustom];
    pickIMG.frame = CGRectMake(17.0f, 16.0f, 46, 46);
    [pickIMG setImage:[UIImage imageNamed:@"anjuke_icon_add_pic4.png"] forState:UIControlStateNormal];
    [pickIMG addTarget:self action:@selector(pickIMG:) forControlEvents:UIControlEventTouchUpInside];
    [self.moreBackView addSubview:pickIMG];
    CGRect imgRect = pickIMG.frame;
    UILabel *imgLab = [[UILabel alloc] initWithFrame:CGRectMake(17.0f, imgRect.origin.y + imgRect.size.height + 8, imgRect.size.width, 30.0f)];
    imgLab.backgroundColor = [UIColor clearColor];
    imgLab.font = [UIFont systemFontOfSize:14];
    imgLab.text = @"相册";
    imgLab.textAlignment = NSTextAlignmentCenter;
    imgLab.textColor = [UIColor axChatPropDescColor:self.isBroker];
    [self.moreBackView addSubview:imgLab];
    
    UIButton *takePic = [UIButton buttonWithType:UIButtonTypeCustom];
    [takePic setImage:[UIImage imageNamed:@"anjuke_icon_add_takephoto4.png"] forState:UIControlStateNormal];
    takePic.frame = CGRectMake(97.0f, 16.0f, 46, 46);
    [takePic addTarget:self action:@selector(takePic:) forControlEvents:UIControlEventTouchUpInside];
    [self.moreBackView addSubview:takePic];
    UILabel *picLab = [[UILabel alloc] initWithFrame:CGRectMake(97.0f, imgRect.origin.y + imgRect.size.height + 8, imgRect.size.width, 30.0f)];
    picLab.backgroundColor = [UIColor clearColor];
    picLab.font = [UIFont systemFontOfSize:14];
    picLab.text = @"拍照";
    picLab.textAlignment = NSTextAlignmentCenter;
    picLab.textColor = [UIColor axChatPropDescColor:self.isBroker];
    [self.moreBackView addSubview:picLab];
    
    UIButton *pickAJK = [UIButton buttonWithType:UIButtonTypeCustom];
    [pickAJK setImage:[UIImage imageNamed:@"anjuke_icon_add_esf.png"] forState:UIControlStateNormal];
    pickAJK.frame = CGRectMake(177.0f, 16.0f, 46, 46);
    [pickAJK addTarget:self action:@selector(pickAJK:) forControlEvents:UIControlEventTouchUpInside];
    [self.moreBackView addSubview:pickAJK];
    UILabel *ajkLab = [[UILabel alloc] initWithFrame:CGRectMake(177.0f, imgRect.origin.y + imgRect.size.height + 8, imgRect.size.width, 30.0f)];
    ajkLab.backgroundColor = [UIColor clearColor];
    ajkLab.font = [UIFont systemFontOfSize:14];
    ajkLab.text = @"二手房";
    ajkLab.textAlignment = NSTextAlignmentCenter;
    ajkLab.textColor = [UIColor axChatPropDescColor:self.isBroker];
    [self.moreBackView addSubview:ajkLab];
    
    UIButton *pickHZ = [UIButton buttonWithType:UIButtonTypeCustom];
    [pickHZ setImage:[UIImage imageNamed:@"anjuke_icon_add_zf.png"] forState:UIControlStateNormal];
    pickHZ.frame = CGRectMake(257.0f, 16.0f, 46, 46);
    [pickHZ addTarget:self action:@selector(pickHZ:) forControlEvents:UIControlEventTouchUpInside];
    [self.moreBackView addSubview:pickHZ];
    UILabel *hzLab = [[UILabel alloc] initWithFrame:CGRectMake(257.0f, imgRect.origin.y + imgRect.size.height + 8, imgRect.size.width, 30.0f)];
    hzLab.backgroundColor = [UIColor clearColor];
    hzLab.font = [UIFont systemFontOfSize:14];
    hzLab.text = @"租房";
    hzLab.textAlignment = NSTextAlignmentCenter;
    hzLab.textColor = [UIColor axChatPropDescColor:self.isBroker];
    [self.moreBackView addSubview:hzLab];
    
    UIButton *location = [UIButton buttonWithType:UIButtonTypeCustom];
    location.frame = CGRectMake(17.0f, 16.0f + 107.0f, 46, 46);
    [location setImage:[UIImage imageNamed:@"anjuke_icon_add_position.png"] forState:UIControlStateNormal];
    [location addTarget:self action:@selector(locationClick) forControlEvents:UIControlEventTouchUpInside];
    [self.moreBackView addSubview:location];
    CGRect locationRect = location.frame;
    UILabel *locationLab = [[UILabel alloc] initWithFrame:CGRectMake(17.0f, locationRect.origin.y + locationRect.size.height + 8, locationRect.size.width, 30.0f)];
    locationLab.backgroundColor = [UIColor clearColor];
    locationLab.font = [UIFont systemFontOfSize:14];
    locationLab.text = @"位置";
    locationLab.textAlignment = NSTextAlignmentCenter;
    locationLab.textColor = [UIColor axChatPropDescColor:self.isBroker];
    [self.moreBackView addSubview:locationLab];
    
}

- (void)initBlock
{
    __weak AXChatViewController *blockSelf = self;
    // 重发消息的block
    self.finishReSendMessageBlock = ^ (NSArray *messages, AXMessageCenterSendMessageStatus status, AXMessageCenterSendMessageErrorTypeCode errorCode) {
        for (AXMappedMessage *message in messages) {
        
        NSMutableDictionary *textData = [NSMutableDictionary dictionary];
        textData = [blockSelf mapAXMappedMessage:message];
        if (textData) {
            if ([message.messageType isEqualToNumber:@(AXMessageTypeSystemTime)]) {
                if (status == AXMessageCenterSendMessageStatusSending) {
                    textData[@"status"] = @(AXMessageCenterSendMessageStatusSuccessful);
                    textData[AXCellIdentifyTag] = message.identifier;
                    [blockSelf appendCellData:textData];
                }
                continue;
            }
            if (status == AXMessageCenterSendMessageStatusSending) {
                textData[@"status"] = @(AXMessageCenterSendMessageStatusSending);
                textData[AXCellIdentifyTag] = message.identifier;
                [blockSelf appendCellData:textData];
                [blockSelf scrollToBottomAnimated:YES];
            } else if (status == AXMessageCenterSendMessageStatusFailed) {
                NSUInteger index = [blockSelf.identifierData indexOfObject:message.identifier];
                blockSelf.cellDict[message.identifier][@"status"] = @(AXMessageCenterSendMessageStatusFailed);
                [blockSelf.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                NSUInteger index = [blockSelf.identifierData indexOfObject:message.identifier];
                blockSelf.cellDict[message.identifier][@"status"] = @(AXMessageCenterSendMessageStatusSuccessful);
                [blockSelf.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
            if (errorCode == AXMessageCenterSendMessageErrorTypeCodeNotFriend && blockSelf.isBroker) {
                [blockSelf sendSystemMessage:AXMessageTypeSystemForbid];
            }
        }
            
        }
    };
    
    self.finishSendMessageBlock = ^ (NSArray *messages, AXMessageCenterSendMessageStatus status, AXMessageCenterSendMessageErrorTypeCode errorCode) {
        for (AXMappedMessage *message in messages) {

        NSMutableDictionary *textData = [NSMutableDictionary dictionary];
        textData = [blockSelf mapAXMappedMessage:message];
        if (textData) {
            if ([message.messageType isEqualToNumber:@(AXMessageTypeSystemTime)]) {
                if (status == AXMessageCenterSendMessageStatusSending) {
                    textData[@"status"] = @(AXMessageCenterSendMessageStatusSuccessful);
                    textData[AXCellIdentifyTag] = message.identifier;
                    [blockSelf appendCellData:textData];
                }
                continue;
            }

            if (status == AXMessageCenterSendMessageStatusSending) {
                textData[@"status"] = @(AXMessageCenterSendMessageStatusSending);
                textData[AXCellIdentifyTag] = message.identifier;
                [blockSelf axAddCellData:textData];
            } else if (status == AXMessageCenterSendMessageStatusFailed) {
                NSUInteger index = [blockSelf.identifierData indexOfObject:message.identifier];
                blockSelf.cellDict[message.identifier][@"status"] = @(AXMessageCenterSendMessageStatusFailed);
                [blockSelf.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                NSUInteger index = [blockSelf.identifierData indexOfObject:message.identifier];
                blockSelf.cellDict[message.identifier][@"status"] = @(AXMessageCenterSendMessageStatusSuccessful);
                [blockSelf.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
            if (errorCode == AXMessageCenterSendMessageErrorTypeCodeNotFriend && blockSelf.isBroker) {
                [blockSelf sendSystemMessage:AXMessageTypeSystemForbid];
            }
        }
        }
    };
}

- (void)fetchLastChatList
{
    AXMappedMessage *lastMessage = [[AXMappedMessage alloc] init];
    lastMessage.sendTime = [NSDate dateWithTimeIntervalSinceNow:0];
    lastMessage.from = self.currentPerson.uid;
    lastMessage.to  = [self checkFriendUid];
    
    __weak AXChatViewController *blockSelf = self;
    
    [[AXChatMessageCenter defaultMessageCenter] fetchChatListWithLastMessage:lastMessage pageSize:AXMessagePageSize callBack:^(NSDictionary *chatList, AXMappedMessage *lastMessage, AXMappedPerson *chattingFriend) {
        blockSelf.hasMore = [chatList[@"hasMore"] boolValue];
        if (blockSelf.hasMore) {
            self.pullToRefreshView.delegate = self;
        } else {
            self.pullToRefreshView.delegate = nil;
        }
        NSArray *chatArray = chatList[@"messages"];
        if ([chatArray isKindOfClass:[NSArray class]] && [chatArray count] > 0) {
            blockSelf.lastMessage = chatArray[0];
            for (AXMappedMessage *mappedMessage in chatArray) {
                NSMutableDictionary *dict = [blockSelf mapAXMappedMessage:mappedMessage];
                if (!dict) {
                    continue;
                }
                if ([mappedMessage.from isEqualToString:[blockSelf checkFriendUid]]) {
                    dict[@"messageSource"] = @(AXChatMessageSourceDestinationIncoming);
                }
                
                [blockSelf.identifierData addObject:mappedMessage.identifier];
                blockSelf.cellDict[mappedMessage.identifier] = dict;
            }
            [blockSelf.myTableView reloadData];
            [blockSelf scrollToBottomAnimated:NO];
        } else {
            if (blockSelf.propDict && [blockSelf.identifierData count] == 0) {
                [blockSelf sendSystemMessage:AXMessageTypeSendProperty];
            }
        }
        
        if ([[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone) {
            [blockSelf sendSystemMessage:AXMessageTypeSettingNotifycation];
        }
        
        [blockSelf addMessageNotifycation];
    }];
}

- (CGSize)sizeOfString:(NSString *)string maxWidth:(float)width withFontSize:(UIFont *)fontSize {
    return [string rtSizeWithFont:fontSize constrainedToSize:CGSizeMake(width, 10000.0f) lineBreakMode:NSLineBreakByCharWrapping];
}

- (void)sendPropMessage
{
    // 如果第一次发消息，发送房源信息
    if (self.propDict && self.needSendProp) {
        NSMutableDictionary *propDict = [NSMutableDictionary dictionaryWithDictionary:self.propDict];
        propDict[@"jsonVersion"] = AXChatJsonVersion;
        self.needSendProp = NO;
        AXMappedMessage *mappedMessageProp = [[AXMappedMessage alloc] init];
        mappedMessageProp.accountType = [self checkAccountType];
        mappedMessageProp.content = [propDict RTJSONRepresentation];
        mappedMessageProp.to = [self checkFriendUid];
        mappedMessageProp.from = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
        mappedMessageProp.isRead = YES;
        mappedMessageProp.isRemoved = NO;
        mappedMessageProp.messageType = @(AXMessageTypeProperty);
        [[AXChatMessageCenter defaultMessageCenter] sendMessage:mappedMessageProp willSendMessage:self.finishSendMessageBlock];
    }
}


- (void)addMessageNotifycation
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewMessage:) name:MessageCenterDidReceiveNewMessage object:nil];
}


#pragma mark - Public Method
- (BOOL)checkUserLogin
{
    return YES;
}

- (void)sendSystemMessage:(AXMessageType)type
{
    self.needSendProp = YES;
    AXMappedMessage *mappedMessageProp = [[AXMappedMessage alloc] init];
    mappedMessageProp.accountType = [self checkAccountType];
    mappedMessageProp.content = @"";
    mappedMessageProp.to = [self checkFriendUid];
    mappedMessageProp.from = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
    mappedMessageProp.isRead = YES;
    mappedMessageProp.isRemoved = NO;
    mappedMessageProp.messageType = @(type);
    
    NSMutableDictionary *textData = [NSMutableDictionary dictionary];
    textData = [self mapAXMappedMessage:mappedMessageProp];
    if (textData) {
        NSString *identifier = [[NSProcessInfo processInfo] globallyUniqueString];
        textData[@"status"] = @(AXMessageCenterSendMessageStatusSuccessful);
        textData[AXCellIdentifyTag] = [NSString stringWithFormat:@"SystemMessage%@", identifier];
        [self appendCellData:textData];
        [self scrollToBottomAnimated:YES];
    }
}

- (NSMutableAttributedString *)configAttributedString:(NSString *)text
{
    NSMutableAttributedString* mas = [NSMutableAttributedString attributedStringWithString:text];
    [mas setFont:[UIFont systemFontOfSize:16]];
    [mas setTextColor:[UIColor blackColor]];
    [mas setTextAlignment:kCTTextAlignmentLeft lineBreakMode:kCTLineBreakByWordWrapping];
    return mas;
}

#pragma mark - Public Method
- (NSDate *)formatterDate:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    NSString *nowDateStr = [df stringFromDate:date];
    return [df dateFromString:nowDateStr];
}

- (void)reloadUnReadNum:(NSInteger)num
{
    // do nothing
}

- (void)sendMessageAppLog
{
    // do nothing
}

- (void)clickRightNavButtonAppLog
{
    // do nothing
}

- (void)clickLeftAvatarAppLog
{
    // do nothing
}

- (void)clickInputViewAppLog
{
    // do nothing
}

- (void)clickLocationLog{
    // do nothing
}
- (void)switchToVoiceLog{
    // do nothing
}
- (void)switchToTextLog{
    // do nothing
}
- (void)pressForVoiceLog{
    // do nothing
}
- (void)cancelSendingVoiceLog{
    // do nothing
}

#pragma mark - DataSouce Method
- (NSString *)checkFriendUid
{
    if (self.uid) {
        return self.uid;
    }
    return @"";
}

- (NSString *)checkAccountType
{
    if (self.isBroker) {
        return @"2";
    } else {
        return @"1";
    }
}

- (NSMutableDictionary *)mapAXMappedMessage:(AXMappedMessage *)mappedMessage
{
    NSNumber *messageSource = @(AXChatMessageSourceDestinationIncoming);
    if (![mappedMessage.to isEqualToString:[[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid]) {
        messageSource = @(AXChatMessageSourceDestinationOutPut);
    } else {
        messageSource = @(AXChatMessageSourceDestinationIncoming);
    }
    NSMutableDictionary *textData;

    switch ([mappedMessage.messageType integerValue]) {
        case AXMessageTypeText:
        {
             textData = [self configTextCellData:[NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeText), @"content":mappedMessage.content, @"messageSource":messageSource}]];
        }
            break;
        case AXMessageTypePic:
        {
            NSData *imgData = nil;
            if (self.isBroker) {
                if (mappedMessage.imgPath.length == 0) {
                    imgData = [NSData dataWithContentsOfFile:mappedMessage.thumbnailImgPath];
                } else {
                    imgData = [NSData dataWithContentsOfFile:mappedMessage.imgPath];
                }
            }else {
                imgData = [NSData dataWithContentsOfFile:mappedMessage.thumbnailImgPath];
            }
            
            if (!imgData) {
                return nil;
            }
            UIImage *img = [UIImage imageWithData:imgData];
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypePic), @"content":img, @"messageSource":messageSource, @"identifier":mappedMessage.identifier}];
        }
            break;
            
        case AXMessageTypeProperty:
        {
            if (![self.contentValidator checkPropertyCard:mappedMessage.content]) {
                return nil;
            }
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeProperty),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
        case AXMessageTypeVoice:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeVoice), @"content":mappedMessage.content, @"messageSource":messageSource, @"identifier":mappedMessage.identifier}];
        }
            break;
        case AXMessageTypeLocation:
        {
//            if (![self.contentValidator checkPropertyCard:mappedMessage.content]) {
//                return nil;
//            }
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeLocation),@"content":mappedMessage.content,@"messageSource":messageSource}];
            
        }
            break;
        case AXMessageTypePublicCard:
        {
            if (![self.contentValidator checkPublicCard:mappedMessage.content]) {
                return nil;
            }
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypePublicCard),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
            
        case AXMessageTypeSystemTime:
        {
            if (!mappedMessage.sendTime) {
                return nil;
            }
            NSTimeInterval since = [[self formatterDate:[NSDate date]] timeIntervalSinceDate:[self formatterDate:mappedMessage.sendTime]];
            NSDateFormatter *dateFormatrer = [[NSDateFormatter alloc] init];
            dateFormatrer.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
            if (since < 3600 * 24) {
                dateFormatrer.dateFormat = @"HH:mm";
            } else {
                dateFormatrer.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            }
            NSString *timeContent =  [dateFormatrer stringFromDate:mappedMessage.sendTime];
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeSystemTime),@"content":timeContent,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
            
        case AXMessageTypeSystemForbid:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeSystemForbid),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];

        }
            break;
        case AXMessageTypeSettingNotifycation:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeSettingNotifycation),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationIncoming)}];
        }
            break;
            
        case AXMessageTypeAddNuckName:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeAddNuckName),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
        case AXMessageTypeAddNote:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeAddNote),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
        case AXMessageTypeSendProperty:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeSendProperty),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
        case AXMessageTypeSafeMessage:
        {
            textData = [NSMutableDictionary dictionaryWithDictionary:@{@"messageType":@(AXMessageTypeSafeMessage),@"content":mappedMessage.content,@"messageSource":@(AXChatMessageSourceDestinationOutPut)}];
        }
            break;
        default:
            break;
    }
    textData[@"mappedMessage"] = mappedMessage;
    if (mappedMessage.identifier) {
        textData[AXCellIdentifyTag] = mappedMessage.identifier;
    }
    if (mappedMessage.sendStatus) {
        textData[@"status"] = mappedMessage.sendStatus;
    }

    return textData;
}

- (void)axAddCellData:(NSDictionary *)msgData
{
    [self.identifierData addObject:msgData[AXCellIdentifyTag]];
    self.cellDict[msgData[AXCellIdentifyTag]] = msgData;
    [self.myTableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)appendCellData:(NSDictionary *)msgData
{
    UITableViewRowAnimation insertAnimation = UITableViewRowAnimationBottom;
    if ([self.identifierData containsObject:msgData[AXCellIdentifyTag]]) {
        NSInteger row = [self.identifierData indexOfObject:msgData[AXCellIdentifyTag]];
        [self.identifierData removeObjectAtIndex:row];
        [self.cellDict removeObjectForKey:msgData[AXCellIdentifyTag]];
        [self.myTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]]  withRowAnimation:UITableViewRowAnimationNone];
        insertAnimation = UITableViewRowAnimationNone;
    }
    [self.identifierData addObject:msgData[AXCellIdentifyTag]];
    self.cellDict[msgData[AXCellIdentifyTag]] = msgData;
    
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    NSIndexPath *newPath =  [NSIndexPath indexPathForRow:[self.identifierData count] - 1 inSection:0];
    [insertIndexPaths addObject:newPath];
    [self.myTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:insertAnimation];
}

- (void)insertCellData:(NSDictionary *)msgData atIndex:(NSUInteger)index
{
    [self.identifierData insertObject:msgData[AXCellIdentifyTag] atIndex:index];
    self.cellDict[msgData[AXCellIdentifyTag]] = msgData;
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    NSIndexPath *newPath =  [NSIndexPath indexPathForRow:index inSection:0];
    [insertIndexPaths addObject:newPath];
    [self.myTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
    [self.myTableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
}

#pragma mark - SSPullToRefresh
- (void)initPullToRefresh
{
    self.pullToRefreshView = [[AXPullToRefreshView alloc] initWithScrollView:self.myTableView delegate:self];
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.identifierData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = (self.identifierData)[[indexPath row]];
    NSDictionary *dic = self.cellDict[identifier];
    if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeProperty)]) {
        // 房源
        return 105 + 20;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeText)]) {
        CGSize sz = [dic[@"mas"] sizeConstrainedToSize:CGSizeMake(kLabelWidth, CGFLOAT_MAX)];
        CGFloat rowHeight = sz.height + 2*kLabelVMargin + 20;
        return rowHeight;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypePic)]) {
        if ([AXChatMessageImageCell sizeOFImg:dic[@"content"]].size.height < 30.0f) {
            return 65.0f;
        }
        return [AXChatMessageImageCell sizeOFImg:dic[@"content"]].size.height + 35.0f;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeSystemTime)]) {
        return 25;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypePublicCard)]) {
        return 290 + 40;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeSystemForbid)]) {
        return 45;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeAddNuckName)]) {
        return 45;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeSettingNotifycation)]) {
        return 60;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeAddNote)]) {
        return 45;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeSendProperty)]) {
        return 45;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeSafeMessage)]) {
        return 75;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeVoice)]) {
        return 65.0f;
    } else if (dic[@"messageType"] && [dic[@"messageType"] isEqualToNumber:@(AXMessageTypeLocation)]) {
        return 140.0f;
    }else {
        return 70;
    }
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = (self.identifierData)[[indexPath row]];
    NSDictionary *dic = self.cellDict[identifier];
    
    AXChatBaseCell *cell = [AXCellFactory cellForTableView:tableView atIndexPath:indexPath withObject:dic withIdentity:[NSString stringWithFormat:@"AXChatCell%@", dic[@"messageType"]]];
    [UIView setAnimationsEnabled:NO];

    cell.delegate = self;
    cell.isBroker = self.isBroker;
    cell.messageSource = [self messageSource:dic];
    cell.messageStatus = AXMessageCenterSendMessageStatusSending;
    if ([dic[@"messageSource"] isEqualToNumber:@(AXChatMessageSourceDestinationOutPut)]) {
        [cell configAvatar:self.currentPerson];
    } else {
        [cell configAvatar:self.friendPerson];
    }
    [cell configWithData:dic];
    [cell configWithIndexPath:indexPath];
    [UIView setAnimationsEnabled:YES];

    return cell;
}

#pragma mark - AJKChatMessageTextCell
- (NSMutableDictionary *)configTextCellData:(NSMutableDictionary *)textData
{
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    CGSize strSize;
    NSMutableAttributedString* mas = [self configAttributedString:textData[@"content"]];
    strSize = [textData[@"content"] rtSizeWithFont:[UIFont systemFontOfSize:16]];
    if (strSize.width > kLabelWidth) {
        maxWidth = kLabelWidth;
        CGSize sz = [mas sizeConstrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
        maxHeight = sz.height;
    } else {
        maxWidth = strSize.width;
        maxHeight = strSize.height;
    }
    textData[@"mas"] = mas;
    textData[@"rowHeight"] = [NSString stringWithFormat:@"%f", maxHeight];
    textData[@"rowWidth"] = [NSString stringWithFormat:@"%f", maxWidth];
    return textData;
}

#pragma mark - AJKChatMessageSystemCellDelegate
- (void)didClickSystemButton:(AXMessageType)messageType {
    
}

- (AXChatMessageSourceDestination)messageSource:(NSDictionary *)dic
{
    if (dic[@"messageSource"] && [dic[@"messageSource"] isEqualToNumber:@(AXChatMessageSourceDestinationIncoming)]) {
        return AXChatMessageSourceDestinationIncoming;
    } else {
        return AXChatMessageSourceDestinationOutPut;
    }
}

- (void)afterSendMessage
{
    
}

#pragma mark - NSNotificationCenter
- (void)didReceiveNewMessage:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)notification.object;
        if (notification.userInfo[@"unreadCount"] && [notification.userInfo[@"unreadCount"] integerValue] > 0) {
            [self reloadUnReadNum:[notification.userInfo[@"unreadCount"] integerValue]];
        }
        if (dict[[self checkFriendUid]]) {
            BOOL flg = NO;
            if (!self.keyboardControl.hidden || (self.myTableView.contentSize.height - self.myTableView.contentOffset.y < AXScrollContentOffsetY)) {
                flg = YES;
            }
            for (AXMappedMessage *mappedMessage in dict[[self checkFriendUid]]) {
                self.lastMessage = mappedMessage;
                NSMutableDictionary *dict = [self mapAXMappedMessage:mappedMessage];
                if (dict) {
                    dict[@"messageSource"] = @(AXChatMessageSourceDestinationIncoming);
                    dict[AXCellIdentifyTag] = mappedMessage.identifier;
                    [self appendCellData:dict];
                }
            }
            // 判断是否需要滑动到底部
            if (flg) {
                [self scrollToBottomAnimated:YES];
            }
        }
    }
}

- (void)willHideEditMenu:(NSNotification *)notification
{
    if (self.selectedCell) {
        if (((AXChatMessageRootCell *)self.selectedCell).messageSource == AXChatMessageSourceDestinationIncoming) {
            ((AXChatMessageRootCell *)self.selectedCell).bubbleIMG.image = [[UIImage axInChatBubbleBg:self.isBroker highlighted:NO] stretchableImageWithLeftCapWidth:40/2 topCapHeight:30/2];
        } else {
            ((AXChatMessageRootCell *)self.selectedCell).bubbleIMG.image = [[UIImage axOutChatBubbleBg:self.isBroker highlighted:NO] stretchableImageWithLeftCapWidth:40/2 topCapHeight:30/2];
        }
    }
}

- (void)willShowEditMenu:(NSNotification *)notification
{
    if (self.selectedCell) {
        if (((AXChatMessageRootCell *)self.selectedCell).messageSource == AXChatMessageSourceDestinationIncoming) {
            ((AXChatMessageRootCell *)self.selectedCell).bubbleIMG.image = [[UIImage axInChatBubbleBg:self.isBroker highlighted:YES] stretchableImageWithLeftCapWidth:40/2 topCapHeight:30/2];
        } else {
            ((AXChatMessageRootCell *)self.selectedCell).bubbleIMG.image = [[UIImage axOutChatBubbleBg:self.isBroker highlighted:YES] stretchableImageWithLeftCapWidth:40/2 topCapHeight:30/2];
        }
    }
}


#pragma mark - SSPullToRefreshViewDelegate
- (void)pullToRefreshViewDidStartLoading:(AXPullToRefreshView *)view {
    if (!self.lastMessage || !self.hasMore) {
        return;
    }
    [self.pullToRefreshView startLoading];
    [self refresh];
}

- (void)refresh {
    [self.pullToRefreshView finishLoading];
}

- (void)pullToRefreshViewDidFinishLoading:(AXPullToRefreshView *)view
{
    __weak AXChatViewController *blockSelf = self;

    [[AXChatMessageCenter defaultMessageCenter] fetchChatListWithLastMessage:self.lastMessage pageSize:AXMessagePageSize callBack:^(NSDictionary *chatList, AXMappedMessage *lastMessage, AXMappedPerson *chattingFriend) {
        blockSelf.hasMore = [chatList[@"hasMore"] boolValue];
        if (blockSelf.hasMore) {
            self.pullToRefreshView.delegate = self;
        } else {
            self.pullToRefreshView.delegate = nil;
        }
        NSArray *chatArray = chatList[@"messages"];
        if ([chatArray isKindOfClass:[NSArray class]] && [chatArray count] > 0) {
            blockSelf.lastMessage = chatArray[0];
            NSInteger num = 0;
            CGFloat cellHeight = 0;
            CGPoint newContentOffset = blockSelf.myTableView.contentOffset;
            NSMutableArray *newIndexPaths = [NSMutableArray array];
            
            for (AXMappedMessage *mappedMessage in chatArray) {
                NSDictionary *dict = [blockSelf mapAXMappedMessage:mappedMessage];
                if (dict) {
                    [blockSelf.identifierData insertObject:mappedMessage.identifier atIndex:num];
                    blockSelf.cellDict[mappedMessage.identifier] = dict;
                    cellHeight += [blockSelf tableView:blockSelf.myTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    
                    NSMutableArray *insertIndexPaths = [NSMutableArray array];
                    NSIndexPath *newPath =  [NSIndexPath indexPathForRow:0 inSection:0];
                    [insertIndexPaths addObject:newPath];
                    num++;
                    [newIndexPaths addObject:[NSIndexPath indexPathForRow:num inSection:0]];
                }
            }
            [blockSelf.myTableView reloadData];
            for (NSIndexPath *indexPath in newIndexPaths) {
                newContentOffset.y += [blockSelf tableView:blockSelf.myTableView heightForRowAtIndexPath:indexPath];
            }
            DLog(@"newContentOffset.y:%f", newContentOffset.y);
            [blockSelf.myTableView setContentOffset:newContentOffset animated:NO];

        }
    }];
}

#pragma mark - ELCImagePickerControllerDelegate
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    if ([info count] == 0) {
        return;
    }
    NSString *uid =[[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
    for (NSDictionary *dict in info) {
        
        UIImage *image = dict[UIImagePickerControllerOriginalImage];
        CGSize size = image.size;
        NSString *name = [NSString stringWithFormat:@"%dx%d",(int)size.width,(int)size.width];
        NSString *path = [AXPhotoManager saveImageFile:image toFolder:AXPhotoFolderName whitChatId:uid andIMGName:name];
        NSString *url = [AXPhotoManager getLibrary:path];
        
        AXMappedMessage *mappedMessage = [[AXMappedMessage alloc] init];
        mappedMessage.accountType = [self checkAccountType];
        //        mappedMessage.content = self.messageInputView.textView.text;
        mappedMessage.to = [self checkFriendUid];
        mappedMessage.from = uid;
        mappedMessage.isRead = YES;
        mappedMessage.isRemoved = NO;
        mappedMessage.messageType = @(AXMessageTypePic);
        mappedMessage.imgUrl = url;
        [[AXChatMessageCenter defaultMessageCenter] sendImage:mappedMessage withCompeletionBlock:self.finishSendMessageBlock];
        
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *uid =[[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    CGSize size = image.size;
    NSString *name = [NSString stringWithFormat:@"%dx%d",(int)size.width,(int)size.width];
    NSString *path = [AXPhotoManager saveImageFile:image toFolder:AXPhotoFolderName whitChatId:uid andIMGName:name];
    NSString *url = [AXPhotoManager getLibrary:path];
    
    AXMappedMessage *mappedMessage = [[AXMappedMessage alloc] init];
    mappedMessage.accountType = [self checkAccountType];
    //        mappedMessage.content = self.messageInputView.textView.text;
    mappedMessage.to = [self checkFriendUid];
    mappedMessage.from = uid;
    mappedMessage.isRead = YES;
    mappedMessage.isRemoved = NO;
    mappedMessage.messageType = @(AXMessageTypePic);
    mappedMessage.imgUrl = url;
    [[AXChatMessageCenter defaultMessageCenter] sendImage:mappedMessage withCompeletionBlock:self.finishSendMessageBlock];
    
    //        UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
    //        NSDictionary *imageData = @{@"messageType":@"image",@"content":image,@"messageSource":@"incoming"};
    //        [self.cellData addObject:imageData];
    //        [self reloadMytableView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AXChatMessageRootCellDelegate
- (void)deleteAXCell:(AXChatMessageRootCell *)axCell
{
    if (![axCell isKindOfClass:[AXChatMessageRootCell class]]) {
        return;
    }
    NSIndexPath *indexPath = [self.myTableView indexPathForCell:axCell];
    NSInteger preRow = indexPath.row - 1;
    NSInteger nextRow = indexPath.row + 1;
    NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:preRow inSection:0];
    NSArray *indexPaths = @[indexPath];
    NSInteger index = 0;
    // 判断是否需要删除系统时间cell
    if (preRow >= 0) {
        NSString *preIdentifier = self.identifierData[preRow];
        NSDictionary *preData = self.cellDict[preIdentifier];
        
        if (nextRow < [self.identifierData count]) {
            NSString *nextIdentifier = self.identifierData[nextRow];
            NSDictionary *nextData = self.cellDict[nextIdentifier];
            if ([preData[@"messageType"] isEqualToNumber:@(AXMessageTypeSystemTime)] &&
                [nextData[@"messageType"] isEqualToNumber:@(AXMessageTypeSystemTime)]) {
                indexPaths = @[preIndexPath, indexPath];
                [self.cellDict removeObjectForKey:preIdentifier];
                [self.identifierData removeObjectAtIndex:preRow];
                index = 1;
                [[AXChatMessageCenter defaultMessageCenter] deleteMessageByIdentifier:preData[AXCellIdentifyTag]];
            }
        } else if (indexPath.row == [self.identifierData count] - 1) {
            if ([preData[@"messageType"] isEqualToNumber:@(AXMessageTypeSystemTime)]) {
                indexPaths = @[preIndexPath, indexPath];
                [self.cellDict removeObjectForKey:preIdentifier];
                [self.identifierData removeObjectAtIndex:preRow];
                index = 1;
                [[AXChatMessageCenter defaultMessageCenter] deleteMessageByIdentifier:preData[AXCellIdentifyTag]];
            }
        }
    }
    NSString *identifier = self.identifierData[indexPath.row - index];
    [self.cellDict removeObjectForKey:identifier];
    [self.identifierData removeObjectAtIndex:indexPath.row - index];
    
    [self.myTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    [[AXChatMessageCenter defaultMessageCenter] deleteMessageByIdentifier:axCell.identifyString];
}

- (void)didOpenAXWebView:(NSString *)url
{
    AXChatWebViewController *chatWebViewController = [[AXChatWebViewController alloc] init];
    chatWebViewController.webUrl = url;
    [self.navigationController pushViewController:chatWebViewController animated:YES];
}

- (void)didMessageRetry:(AXChatMessageRootCell *)axCell
{
    if (self.friendPerson.userType == AXPersonTypePublic) {
        if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeText)]){
            [[AXChatMessageCenter defaultMessageCenter] reSendMessageToPublic:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
        }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeProperty)]){
            [[AXChatMessageCenter defaultMessageCenter] reSendMessageToPublic:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
        }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeLocation)]){
            [[AXChatMessageCenter defaultMessageCenter] reSendMessageToPublic:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
        }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeVoice)]){
            [[AXChatMessageCenter defaultMessageCenter] reSendVoiceToPublic:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
        }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypePic)]){
            [[AXChatMessageCenter defaultMessageCenter] reSendImageToPublic:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
        }else {
            
        }
        // 之后必改
    } else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypePic)]){
        [[AXChatMessageCenter defaultMessageCenter] reSendImage:axCell.identifyString withCompeletionBlock:self.finishReSendMessageBlock];
    }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeText)]){
        [[AXChatMessageCenter defaultMessageCenter] reSendMessage:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
    }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeLocation)]){
        [[AXChatMessageCenter defaultMessageCenter] reSendMessage:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
    }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeProperty)]){
        [[AXChatMessageCenter defaultMessageCenter] reSendMessage:axCell.identifyString willSendMessage:self.finishReSendMessageBlock];
    }else if([axCell.rowData[@"messageType"]  isEqual: @(AXMessageTypeVoice)]){
        [[AXChatMessageCenter defaultMessageCenter] reSendVoice:axCell.identifyString withCompeletionBlock:self.finishReSendMessageBlock];
    }else {
        
    }
}
- (void)didClickVoice:(AXChatMessageRootCell *)axCell
{
    if (![axCell isKindOfClass:[AXChatMessageRootCell class]]) {
        return;
    }
    // 更新数据库
    AXMappedMessage *message = axCell.rowData[@"mappedMessage"];
    NSString *preIdentifier = [self.playingIdentifier copy];
    [self cancelKKAudioPlaying];
    if ([preIdentifier isEqualToString:message.identifier]) {
        return;
    }
    // 更新数据库
    NSMutableDictionary *data = [message.content JSONValue];
    if (data && !data[@"hadDone"]) {
        data[@"hadDone"] = @"1";
        message.content = [data RTJSONRepresentation];
        NSMutableDictionary *dict = self.cellDict[message.identifier];
        if (dict) {
            dict[@"content"] = [data RTJSONRepresentation];
            self.cellDict[message.identifier] = dict;
        }
        
        [[AXChatMessageCenter defaultMessageCenter] updateMessageWithIdentifier:message.identifier keyValues:@{@"content":message.content}];
    }
    
    // 播放
    self.playingIdentifier = message.identifier;
    [[KKAudioComponent sharedAudioComponent] playRecordingWithRelativeFilePath:message.imgPath];
    if (!self.playTipView) {
        UIView* view = [KKAudioComponent sharedAudioComponent].playTipView;
        [self.view addSubview:view];
        self.playTipView = YES;
    }
    __weak AXChatViewController *blockObject = self;
    [KKAudioComponent sharedAudioComponent].playDidFinishBlock = ^{
        [blockObject cancelKKAudioPlaying];
    
    };
    
}
- (void)cancelKKAudioPlaying
{
    // 停止播放
    if ([self.playingIdentifier isEqualToString:@""]) {
        return;
    }
    [[KKAudioComponent sharedAudioComponent] cancelPlaying];
    NSInteger index = [self.identifierData indexOfObject:self.playingIdentifier];
    self.playingIdentifier = @"";
    if (index >= 0) {
        [self.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}
#pragma mark - Layout message input view

- (void)layoutAndAnimateMessageInputTextView:(UITextView *)textView
{
    CGFloat maxHeight = [JSMessageInputView maxHeight];
    
    BOOL isShrinking = textView.contentSize.height < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textView.contentSize.height - self.previousTextViewContentHeight;
    
    if (!isShrinking && (self.previousTextViewContentHeight == maxHeight || textView.text.length == 0)) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    if (changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             [self setTableViewInsetsWithBottomValue:self.myTableView.contentInset.bottom + changeInHeight];
                             
                             [self scrollToBottomAnimated:NO];
                             
                             if (isShrinking) {
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.messageInputView adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.messageInputView.frame;
                             self.messageInputView.frame = CGRectMake(0.0f,
                                                                      inputViewFrame.origin.y - changeInHeight,
                                                                      inputViewFrame.size.width,
                                                                      inputViewFrame.size.height + changeInHeight);
                             
                             if (!isShrinking) {
                                 // growing the view, animate the text view frame AFTER input view frame
                                 [self.messageInputView adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                         }];
        
        self.previousTextViewContentHeight = MIN(textView.contentSize.height, maxHeight);
    }
    
    // Once we reached the max height, we have to consider the bottom offset for the text view.
    // To make visible the last line, again we have to set the content offset.
    if (self.previousTextViewContentHeight == maxHeight) {
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime,
                       dispatch_get_main_queue(),
                       ^(void) {
                           CGPoint bottomOffset = CGPointMake(0.0f, textView.contentSize.height - textView.bounds.size.height);
                           [textView setContentOffset:bottomOffset animated:YES];
                       });
    }
}

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom
{
    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
    self.myTableView.contentInset = insets;
    self.myTableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        insets.top = self.topLayoutGuide.length;
    }
    
    insets.bottom = bottom;
    
    return insets;
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.messageInputView.textView && [keyPath isEqualToString:@"contentSize"]) {
        [self layoutAndAnimateMessageInputTextView:object];
    }
}

#pragma mark - Keyboard notifications

- (void)handleWillShowKeyboardNotification:(NSNotification *)notification
{
    self.moreBackView.hidden = YES;
    [self keyboardWillShowHide:notification];
    self.keyboardControl.hidden = NO;
}

- (void)handleWillHideKeyboardNotification:(NSNotification *)notification
{
    if (!self.moreBackView.hidden) {
        self.preNotification = notification;
        return;
    }
    [self keyboardWillShowHide:notification];
    self.keyboardControl.hidden = YES;
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    CGRect keyboardRect = [(notification.userInfo)[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
    CGRect inputViewFrame = self.messageInputView.frame;
    CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;
    
    // for ipad modal form presentations
    CGFloat messageViewFrameBottom = self.view.frame.size.height - inputViewFrame.size.height;
    if (inputViewFrameY > messageViewFrameBottom)
        inputViewFrameY = messageViewFrameBottom;
    
    self.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
                                             inputViewFrameY,
                                             inputViewFrame.size.width,
                                             inputViewFrame.size.height);

    [self setTableViewInsetsWithBottomValue:self.view.frame.size.height
     - self.messageInputView.frame.origin.y
     - inputViewFrame.size.height ];
    self.keyboardControl.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height
                                            - self.messageInputView.frame.origin.y
                                            - inputViewFrame.size.height);
    [self scrollToBottomAnimated:YES];
    [UIView commitAnimations];
}

#pragma mark - Dismissive text view delegate
- (void)keyboardDidScrollToPoint:(CGPoint)point
{
    CGRect inputViewFrame = self.messageInputView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:point fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

- (void)keyboardWillBeDismissed
{
    CGRect inputViewFrame = self.messageInputView.frame;
    inputViewFrame.origin.y = self.view.bounds.size.height - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

- (void)keyboardWillSnapBackToPoint:(CGPoint)point
{
    if (!self.tabBarController.tabBar.hidden){
        return;
    }
	
    CGRect inputViewFrame = self.messageInputView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:point fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}
- (void)sendRecored
{
    NSDictionary *dict = [[KKAudioComponent sharedAudioComponent] finishRecording];
//    self.isRecording = NO;
//    [self.recordTimer invalidate];
    
    if (!dict) {
//        self.recordErrorHUD.hidden = NO;
//        [self performSelector:@selector(hideDelayed:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];
        return;
    }
    CGFloat cTime = [dict[@"RECORD_TIME"] floatValue];
    DLog(@"cTime:%f", cTime);
    if (cTime <= 1) {
//        self.recordErrorHUD.hidden = NO;
//        [self performSelector:@selector(hideDelayed:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5f];
    } else {
        // 发送
        AXMappedMessage *mappedMessage = [[AXMappedMessage alloc] init];
        mappedMessage.accountType = [self checkAccountType];
        mappedMessage.content = [@{@"jsonVersion":AXChatJsonVersion, @"length":[NSString stringWithFormat:@"%d", [[NSNumber numberWithFloat:cTime] integerValue]]} RTJSONRepresentation];
        mappedMessage.to = [self checkFriendUid];
        mappedMessage.from = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
        mappedMessage.isRead = YES;
        mappedMessage.isRemoved = NO;
        mappedMessage.messageType = @(AXMessageTypeVoice);
        mappedMessage.imgPath = [KKAudioComponent relativeFilePathWithFileName:dict[@"FILE_NAME"] ofType:@"wav"];
        if (self.friendPerson && self.friendPerson.userType == AXPersonTypePublic) {
            [[AXChatMessageCenter defaultMessageCenter] sendVoiceToPublic:mappedMessage willSendMessage:self.finishSendMessageBlock];
        }else{
            [[AXChatMessageCenter defaultMessageCenter] sendVoice:mappedMessage withCompeletionBlock:self.finishSendMessageBlock];
        }
    }
}
#pragma mark - Utilities

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;
            
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
            
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
            
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
            
        default:
            return kNilOptions;
    }
}

#pragma mark - Actions

- (void)didClickKeyboardControl
{
    if (self.moreBackView && !self.moreBackView.hidden) {
        self.moreBackView.hidden = YES;
        if (self.preNotification) {
            [self keyboardWillShowHide:self.preNotification];
        }else {
            if (self.isBroker) {
                //            CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.27f];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                [UIView setAnimationBeginsFromCurrentState:YES];
                CGFloat keyboardY = AXMoreBackViewHeight;
                CGRect inputViewFrame = self.messageInputView.frame;
                CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;
                
                // for ipad modal form presentations
                CGFloat messageViewFrameBottom = self.view.frame.size.height - inputViewFrame.size.height;
                if (inputViewFrameY > messageViewFrameBottom) {
                    inputViewFrameY = messageViewFrameBottom;
                }
                self.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
                                                         AXWINDOWHEIGHT -AXNavBarHeight -AXStatuBarHeight - inputViewFrame.size.height,
                                                         inputViewFrame.size.width,
                                                         inputViewFrame.size.height);
                
                [self setTableViewInsetsWithBottomValue:self.view.frame.size.height
                 - self.messageInputView.frame.origin.y
                 - inputViewFrame.size.height + 60];
                self.keyboardControl.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height
                                                        - self.messageInputView.frame.origin.y
                                                        - inputViewFrame.size.height + 60);
                self.keyboardControl.hidden = YES;
                [UIView commitAnimations];
            }
        }
    } else {
        [self.messageInputView.textView resignFirstResponder];
    }
}


- (void)didMoreBackView:(UIButton *)sender
{
    CGRect moreRect = CGRectMake(0, AXWINDOWHEIGHT - AXNavBarHeight - AXStatuBarHeight - AXMoreBackViewHeight, AXWINDOWWHIDTH, AXMoreBackViewHeight);
    self.moreBackView.frame = CGRectMake(moreRect.origin.x, moreRect.origin.y + AXMoreBackViewHeight, moreRect.size.width, moreRect.size.height);
    if (self.moreBackView.hidden) {//当more为消失状态时
        self.moreBackView.hidden = !self.moreBackView.hidden;
        [self.messageInputView.textView resignFirstResponder];

        [UIView animateWithDuration:0.270f animations:^{
            self.moreBackView.frame = moreRect;
            
            CGRect inputViewFrame = self.messageInputView.frame;
            CGFloat inputViewFrameY = AXWINDOWHEIGHT -AXNavBarHeight -AXStatuBarHeight - AXMoreBackViewHeight - inputViewFrame.size.height;
            self.keyboardControl.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height
                                                    - AXMoreBackViewHeight
                                                    - inputViewFrame.size.height + 60);
            self.keyboardControl.hidden = NO;
            self.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
                                                     inputViewFrameY,
                                                     inputViewFrame.size.width,
                                                     inputViewFrame.size.height);

            if (self.isVoiceInput) {
                self.isVoiceInput = !self.isVoiceInput;
                self.pressSpeek.frame = CGRectZero;
                [self.voiceBut setImage:[UIImage imageNamed:SpeekImgNameVoice] forState:UIControlStateNormal];
                self.messageInputView.textView.editable = YES;
                self.messageInputView.textView.selectable = YES;
            }
            
            [self setTableViewInsetsWithBottomValue:self.view.frame.size.height
             - self.messageInputView.frame.origin.y
             - inputViewFrame.size.height ];
            [self scrollToBottomAnimated:YES];
        } completion:nil];
    }else {
        self.moreBackView.hidden = !self.moreBackView.hidden;
        [self.messageInputView.textView becomeFirstResponder];
    }
    
}


- (void)sendPressed:(UIButton *)sender
{
    [self sendMessage:self.messageInputView.textView];
}

- (void)finishSend
{
    self.messageInputView.textView.text = @"";
    [self textViewDidChange:self.messageInputView.textView];
    [self.myTableView reloadData];
}

- (void)goBrokerPage:(id)sender
{
    
}

- (void)pickIMG:(id)sender {
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] init];
    elcPicker.maximumImagesCount = 5; //(maxCount - self.roomImageArray.count);
    elcPicker.imagePickerDelegate = self;
    [self presentViewController:elcPicker animated:YES completion:nil];
}

- (void)takePic:(id)sender {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera; //拍照
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
    
}
- (void)pickHZ:(id)sender {
    
}
- (void)pickAJK:(id)sender {
    
}


- (void)locationClick {
    [self clickLocationLog];
    MapViewController *mv = [[MapViewController alloc] init];
    mv.siteDelegate = self;
    [mv setHidesBottomBarWhenPushed:YES];
    mv.mapType = RegionChoose;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController pushViewController:mv animated:YES];

}


- (void)speeking {
    
    if (!self.moreBackView.isHidden) {
        [self didClickKeyboardControl];
    }
    if (!self.isVoiceInput) {
        self.isVoiceInput = !self.isVoiceInput;
        [self.voiceBut setImage:[UIImage imageNamed:SpeekImgNameKeyboard] forState:UIControlStateNormal];
        [self.messageInputView.textView resignFirstResponder];
        self.messageInputView.textView.editable = NO;
//        self.messageInputView.textView.selectable = NO;
        self.pressSpeek.frame = self.messageInputView.textView.frame;
        self.pressSpeek.height = AXInputBackViewHeight;
        [self switchToVoiceLog];
    } else {
        self.isVoiceInput = !self.isVoiceInput;
        self.pressSpeek.frame = CGRectZero;
        [self.voiceBut setImage:[UIImage imageNamed:SpeekImgNameVoice] forState:UIControlStateNormal];
        self.messageInputView.textView.editable = YES;
//        self.messageInputView.textView.selectable = YES;
        [self.messageInputView.textView becomeFirstResponder];
        [self switchToTextLog];
    }

}
- (void)didClickRecored:(id)sender
{
    __weak AXChatViewController *blockSelf = self;
    PermissionBlock permissionBlock = ^(BOOL granted) {
        if (granted) {
            [blockSelf didBeginVoice];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法录音" message:@"请在iPhone的“设置-隐私-麦克风”选项中，允许安居客访问你的手机麦克风。" delegate:blockSelf cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            [alertView show];
        }
    };
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:permissionBlock];
    } else {
        [self didBeginVoice];
        [self pressForVoiceLog];
    }
}

//UIControlEventTouchDown
- (void)didBeginVoice {
    self.curCount = 0;
    self.isInterrupted = NO;
    self.date = [NSDate date];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[KKAudioComponent sharedAudioComponent] beginRecording];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateVolumn) userInfo:nil repeats:YES];

    //延迟创建
    if (self.backgroundImageView == nil) {
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 310/2, 290/2)];
        
        self.microphoneImageView = [[UIImageView alloc] initWithFrame:CGRectMake(310/2/2 - 88/2/2, 290/2/2-170/2/2 - 10, 88/2, 145/2)];
        self.highlightedMicrophoneImageView = [[UIImageView alloc] initWithFrame:CGRectMake(310/2/2 - 88/2/2, 290/2/2-170/2/2 - 10, 88/2, 145/2)];
        
        self.dustbinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(310/2/2 - 128/2/2, 290/2/2-150/2/2 - 10, 128/2, 121/2)];
        
        self.hudLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 115, 155, 20)];
        self.hudLabel.font = [UIFont systemFontOfSize:15];
        self.hudLabel.backgroundColor = [UIColor clearColor];
        self.hudLabel.textColor = [UIColor whiteColor];
        self.hudLabel.textAlignment = NSTextAlignmentCenter;
        
        self.countDownLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 160, 145, 25)];
        self.countDownLabel.font = [UIFont systemFontOfSize:15];
        self.countDownLabel.layer.cornerRadius = 5;
        self.countDownLabel.layer.masksToBounds = YES;
        self.countDownLabel.alpha = 0.7;
        self.countDownLabel.backgroundColor = [UIColor blackColor];
        self.countDownLabel.textColor = [UIColor whiteColor];
        self.countDownLabel.textAlignment = NSTextAlignmentCenter;
        self.countDownLabel.hidden = YES;
        
        [self.backgroundImageView addSubview:self.microphoneImageView];
        [self.backgroundImageView addSubview:self.highlightedMicrophoneImageView];
        [self.backgroundImageView addSubview:self.dustbinImageView];
        [self.backgroundImageView addSubview:self.hudLabel];
        [self.backgroundImageView addSubview:self.countDownLabel];
        
    }
    self.dustbinImageView.image = nil;
    self.microphoneImageView.image = nil;
    self.highlightedMicrophoneImageView.image = nil;
    self.backgroundImageView.image = nil;
    
    self.microphoneImageView.image = [UIImage imageNamed:@"wl_voice_icon_voicestatu"];
    self.backgroundImageView.image = [UIImage imageNamed:@"wl_voice_tip_bg"];
    [self showHUDWithTitle:@"手指上滑, 取消发送" CustomView:self.backgroundImageView IsDim:NO]; //取消蒙版
    
}

//UIControlEventTouchUpInside
- (void)didCommitVoice {
    self.countDownLabel.hidden = YES;
    
    if (self.isInterrupted) {
        return;
    }
    
    double timeSpent = [[NSDate date] timeIntervalSinceDate:self.date];
    if (timeSpent < 1) {
        [self.timer invalidate];
        self.dustbinImageView.image = nil;
        self.microphoneImageView.image = nil;
        self.highlightedMicrophoneImageView.image = nil;
        self.backgroundImageView.image = nil;
        
        self.backgroundImageView.image = [UIImage imageNamed:@"wl_voice_tip_warn"];
        self.hudLabel.text = @"录音时间太短";
        [self.hud hide:YES afterDelay:1];
        
    }else{
//        [[KKAudioComponent sharedAudioComponent] finishRecording];
        [self sendRecored];
        [self.timer invalidate];
        [self hideHUD];
    }
    
}

//UIControlEventTouchUpOutside
- (void)didCancelVoice{
    self.countDownLabel.hidden = YES;
    
    if (self.isInterrupted) {
        return;
    }
    
    self.pressSpeek.selected = NO;
    [[KKAudioComponent sharedAudioComponent] cancelRecording];
    [self.timer invalidate];
    
    [self.hud hide:YES];
    [self cancelSendingVoiceLog];
    
}

//UIControlEventTouchDragExit
- (void)willCancelVoice {
    if (self.isInterrupted) {
        return;
    }
    
    [self.timer invalidate];
    
    self.countDownLabel.hidden = YES;
    self.pressSpeek.selected = YES;
    
    self.dustbinImageView.image = nil;
    self.microphoneImageView.image = nil;
    self.highlightedMicrophoneImageView.image = nil;
    self.backgroundImageView.image = nil;

    self.dustbinImageView.image = [UIImage imageNamed:@"wl_voice_icon_dustbin"];
    self.backgroundImageView.image = [UIImage imageNamed:@"wl_voice_tip_bg2"];

    self.hudLabel.text = @"手指松开, 取消发送";
    [self.pressSpeek setTitle:@"手指松开, 取消发送" forState:UIControlStateSelected];
    
}


//UIControlEventTouchDragEnter
- (void)continueRecordVoice{
    if (self.isInterrupted) {
        return;
    }
    
    self.pressSpeek.selected = NO;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateVolumn) userInfo:nil repeats:YES];
    
    self.dustbinImageView.image = nil;
    self.microphoneImageView.image = nil;
    self.highlightedMicrophoneImageView.image = nil;
    self.backgroundImageView.image = nil;
    
    self.microphoneImageView.image = [UIImage imageNamed:@"wl_voice_icon_voicestatu"];
    self.backgroundImageView.image = [UIImage imageNamed:@"wl_voice_tip_bg"];
    
    self.hudLabel.text = @"手指上滑, 取消发送";
}


//使用 MBProgressHUD
- (void)showHUDWithTitle:(NSString*)title CustomView:(UIView*)view IsDim:(BOOL)isDim {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.color = [UIColor clearColor];
    self.hud.customView = view;
    self.hud.yOffset = -20;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.dimBackground = isDim;
    self.hudLabel.text = title;
    
}

//使用 MBProgressHUD 显示完成提示
- (void)showHUDWithTitle:(NSString *)title CustomView:(UIView *)view IsDim:(BOOL)isDim IsHidden:(BOOL)isHidden{
    
    [self showHUDWithTitle:title CustomView:view IsDim:isDim];
    if (isHidden) {
        [self.hud hide:YES afterDelay:1];
    }
    
}


- (void)hideHUD {
    self.countDownLabel.hidden = YES;
    [self.hud hide:YES];
}

- (void)updateVolumn
{
    
    double lowPassResults = [[KKAudioComponent sharedAudioComponent] volumnUpdated];
    int value = (0.8 - lowPassResults) * 60;
    
    UIImage* image = [UIImage imageNamed:@"wl_voice_icon_voicestatu1"];
    self.highlightedMicrophoneImageView.frame = CGRectMake(310/2/2 - 88/2/2, 290/2/2-170/2/2 + value -10, 88/2, 145/2 -value); //变更frame
    CGRect rect = CGRectMake(0, value*2, 88, 145 - value*2);//创建矩形框, retina图像需要*2
    self.highlightedMicrophoneImageView.image = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([image CGImage], rect)];
    
    if (self.curCount >= MAX_RECORD_TIME - 10 && self.curCount < MAX_RECORD_TIME) {
        //剩下10秒
        self.countDownLabel.hidden = NO;
        self.countDownLabel.text = [NSString stringWithFormat:@"录音时间还剩%d秒",(int)(MAX_RECORD_TIME - self.curCount)];
    }else if (self.curCount >= MAX_RECORD_TIME){
        //时间到
        [self didCommitVoice];
        self.isInterrupted = YES;//标志位表示被强制结束录音
    }
    self.curCount += 0.1f; //计时器每0.1秒调用一次, 这儿进行计时
    
}

- (void)sendMessage:(id)sender {
    
    if ([self.messageInputView.textView.text isEqualToString:@""]) {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"提示" message:@"不能发空消息" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [view show];
        return;
    }
    
    if ([self.messageInputView.textView.text length] >= 2000) {
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"提示" message:@"超出字数限制" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [view show];
        return;
    }
    
    AXMappedMessage *mappedMessage = [[AXMappedMessage alloc] init];
    mappedMessage.accountType = [self checkAccountType];
    mappedMessage.content = self.messageInputView.textView.text;
    mappedMessage.to = [self checkFriendUid];
    mappedMessage.from = [[AXChatMessageCenter defaultMessageCenter] fetchCurrentPerson].uid;
    mappedMessage.isRead = YES;
    mappedMessage.isRemoved = NO;
    mappedMessage.messageType = @(AXMessageTypeText);
    
    if (self.friendPerson.userType == AXPersonTypePublic) {
        [[AXChatMessageCenter defaultMessageCenter] sendMessageToPublic:mappedMessage willSendMessage:self.finishSendMessageBlock];
    } else {
        [[AXChatMessageCenter defaultMessageCenter] sendMessage:mappedMessage willSendMessage:self.finishSendMessageBlock];
    }
    [self afterSendMessage];
    [self sendPropMessage];
    
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (void)didClickPublicCardWithUrl:(NSString *)url
{
    AXChatWebViewController *webViewController = [[AXChatWebViewController alloc] init];
    webViewController.webUrl = url;
    webViewController.webTitle = self.friendPerson.name;
    [self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark - Scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	self.isUserScrolling = YES;
    [self.messageInputView.textView resignFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.isUserScrolling = NO;
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSInteger rows = [self.myTableView numberOfRowsInSection:0];
    if (rows > 0) {
        [self.myTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                                atScrollPosition:UITableViewScrollPositionBottom
                                        animated:animated];
    }
}

#pragma mark - Text view delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (!self.isBroker) {
        // 检查用户是否登陆
        if (![self checkUserLogin]) {
            return NO;
        }
    }
    [self clickInputViewAppLog];
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
	
    if (!self.previousTextViewContentHeight) {
		self.previousTextViewContentHeight = textView.contentSize.height;
    }
    [self scrollToBottomAnimated:YES];
    if (![self.messageInputView.textView.text isEqualToString:@""]) {
        self.messageInputView.sendButton.enabled = YES;
    } else {
        self.messageInputView.sendButton.enabled = NO;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self sendMessage:textView.text];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *text = [textView.text js_stringByTrimingWhitespace];
    NSData *data = [text dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    NSString *asciiString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!self.isBroker && [text length] > 0 && ![text isEqualToString:@""] && ([asciiString rangeOfString:@"\\ufffc"].location == NSNotFound || [asciiString length] == 0)) {
        self.messageInputView.sendButton.enabled = YES;
    } else {
        self.messageInputView.sendButton.enabled = NO;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    self.messageInputView.sendButton.enabled = NO;
}
- (void)didClickMapCell:(NSDictionary *)dic {

}
- (void)didClickIMG:(AXChatBaseCell *)axCell {
    NSIndexPath *indexPath = [self.myTableView indexPathForCell:axCell];
    NSString *identifier = (self.identifierData)[[indexPath row]];
    NSDictionary *dic = self.cellDict[identifier];
    if ([dic[@"messageType"] isEqualToNumber:@(AXMessageTypePic)]) {
        NSMutableArray *imgArray = [NSMutableArray arrayWithArray:[[AXChatMessageCenter defaultMessageCenter] picMessageArrayWithFriendUid:[self checkFriendUid]]];
        
        NSArray *temparray = [[imgArray reverseObjectEnumerator] allObjects];
        NSMutableArray *photoArray = [NSMutableArray array];
        int currentPhotoIndex = 0;
        for (int i =0; i <temparray.count; i ++) {
            AXPhoto *photo = [[AXPhoto alloc] init];
            photo.picMessage = temparray[i];
            if ([dic[@"identifier"] isEqualToString:photo.picMessage.identifier]) {
                currentPhotoIndex = i;
            }
            [photoArray addObject:photo];
        }
        AXPhotoBrowser *controller = [[AXPhotoBrowser alloc] init];
        controller.isBroker = YES;
        controller.currentPhotoIndex = currentPhotoIndex; // 弹出相册时显示的第一张图片是？
        [controller setPhotos:photoArray]; // 设置所有的图片
        [self.navigationController pushViewController:controller animated:YES];
    }
}
-(void)loadMapSiteMessage:(NSDictionary *)mapSiteDic {

}
@end
