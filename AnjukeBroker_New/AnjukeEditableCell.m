//
//  AnjukeEditableCell.m
//  AnjukeBroker_New
//
//  Created by Wu sicong on 13-10-28.
//  Copyright (c) 2013年 Wu sicong. All rights reserved.
//

#import "AnjukeEditableCell.h"
#import "Util_UI.h"

@implementation AnjukeEditableCell
@synthesize text_Field;
@synthesize editDelegate;
@synthesize unitLb;
@synthesize inputed_RowAtCom0, inputed_RowAtCom1, inputed_RowAtCom2;
@synthesize titleLb;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        self.backgroundView = [self baseCellBackgroundView];
    }
    return self;
}

- (void)initUI {
    self.textLabel.textColor = SYSTEM_DARK_GRAY;
    
    self.inputed_RowAtCom0 = 0;
    self.inputed_RowAtCom1 = 0;
    self.inputed_RowAtCom2 = 0;
    
    UILabel *comTitleLb = [[UILabel alloc] initWithFrame:CGRectMake(CELL_OFFSET_TITLE, (CELL_HEIGHT - 20)/2, 90, 20)];
    comTitleLb.backgroundColor = [UIColor clearColor];
    comTitleLb.textColor = SYSTEM_DARK_GRAY;
    comTitleLb.font = [UIFont systemFontOfSize:17];
    self.titleLb = comTitleLb;
    [self.contentView addSubview:comTitleLb];
    
    //text field
    UITextField *cellTextField = nil;
    cellTextField = [[UITextField alloc] initWithFrame:CGRectMake(224/2, 3,  150, CELL_HEIGHT - 1*5)];
    cellTextField.returnKeyType = UIReturnKeyDone;
    cellTextField.backgroundColor = [UIColor clearColor];
    cellTextField.borderStyle = UITextBorderStyleNone;
    cellTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cellTextField.text = @"";
    cellTextField.clearButtonMode = UITextFieldViewModeNever;
    cellTextField.placeholder = @"";
    cellTextField.delegate = self;
    cellTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    cellTextField.font = [UIFont systemFontOfSize:17];
    cellTextField.secureTextEntry = NO;
    cellTextField.textColor = SYSTEM_BLACK;
    self.text_Field = cellTextField;
    [self.contentView addSubview:cellTextField];
    
    CGFloat unitLbW = 40;
    UILabel *lb2 = [[UILabel alloc] initWithFrame:CGRectMake(320 - 15 - unitLbW, (CELL_HEIGHT - 20)/2, unitLbW, 20)];
    lb2.backgroundColor = [UIColor clearColor];
    lb2.font = [UIFont systemFontOfSize:17];
    lb2.textColor = [UIColor brokerMiddleGrayColor];
    self.unitLb = lb2;
    [self.contentView addSubview:lb2];
    
    [self showBottonLineWithCellHeight:CELL_HEIGHT];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (BOOL)configureCell:(id)dataModel {
    if (![dataModel isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSString *title = (NSString *)dataModel;
    
    //title
//    self.textLabel.text = title;
//    self.textLabel.font = [UIFont systemFontOfSize:CELL_TITLE_FONT];
    self.titleLb.text = title;
    
    return YES;
}

#pragma mark - TextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self.editDelegate respondsToSelector:@selector(textFieldBeginEdit:)]) {
        [self.editDelegate textFieldBeginEdit:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.editDelegate respondsToSelector:@selector(textFieldDidEndEdit:)]) {
        [self.editDelegate textFieldDidEndEdit:text_Field.text];
    }
}

@end
