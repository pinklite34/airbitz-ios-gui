//
//  SignUpUsernameController.m
//  AirBitz
//

#import "SignUpUsernameController.h"
#import "MinCharTextField.h"
#import "LatoLabel.h"
#import "Util.h"
#import "User.h"

@interface SignUpUsernameController () <UITextFieldDelegate>
{
    UITextField                     *_activeTextField;

}

@property (nonatomic, weak) IBOutlet MinCharTextField           *userNameTextField;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (nonatomic, assign)   BOOL                            bSuccess;
@property (nonatomic, copy)     NSString                        *strReason;
@property (nonatomic, copy)     NSString                        *labelString;
@property (weak, nonatomic) IBOutlet UILabel                    *infoText;


@end

@implementation SignUpUsernameController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_userNameTextField.delegate = self;
    _userNameTextField.minimumCharacters = [CoreBridge getMinimumUsernamedLength];

    self.labelString = NSLocalizedString(@"Sign Up", @"Sign Up");

    if (self.manager.strInUserName) {
        self.userNameTextField.text = self.manager.strInUserName;
    }

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    NSString *tempText = signupUsernameText;
    [Util replaceHtmlTags:&tempText];
    self.infoText.text = tempText;
    [self.view addSubview:self.buttonBlocker];

}


-(void)viewWillAppear:(BOOL)animated {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self.userNameTextField becomeFirstResponder];

}


- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

-(IBAction)back:(id)sender
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         CGRect frame = self.view.frame;
                         frame.origin.x = frame.size.width;
                         self.view.frame = frame;
                     }
                     completion:^(BOOL finished)
                     {
                         [self exitWithBackButton:YES];
                     }];
}

- (void) next
{
    [self blockUser:YES];
    // if they entered a valid username or old password
    if ([self userNameFieldIsValid] == YES)
    {
        // check the username and pin field
        if ([self fieldsAreValid] == YES) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                ABCConditionCode ccode = [[AppDelegate abc] isAccountUsernameAvailable:self.userNameTextField.text];

                if (ABCConditionCodeOk == ccode)
                {
                    _bSuccess = true;
                }
                else
                {
                    _bSuccess = false;
                }
                _strReason = [[AppDelegate abc] getLastErrorString];

                [self performSelectorOnMainThread:@selector(checkUsernameComplete) withObject:nil waitUntilDone:FALSE];
            });
        } else {
            [self blockUser:NO];
        }
    }
    else
    {
        [self blockUser:NO];
    }

}

- (void)checkUsernameComplete
{
    if (_bSuccess) {
        [self.userNameTextField resignFirstResponder];
        self.manager.strUserName = [NSString stringWithFormat:@"%@",self.userNameTextField.text];
        [super next];
    } else {
//        [self dismissFading:NO];
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signin error alert")
                      message:[NSString stringWithFormat:@"Sign-Up failed:\n%@", _strReason]
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
    }
    [self blockUser:NO];
}

- (IBAction)buttonBlockerTouched:(id)sender
{
}

#pragma mark - Misc Methods

// checks the username field (non-blank or matches old password)
// returns YES if field is good
// if the field is bad, an appropriate message box is displayed
- (BOOL)userNameFieldIsValid
{
    BOOL bUserNameFieldIsValid = YES;

    // if nothing was entered
    if ([self.userNameTextField.text length] == 0)
    {
        bUserNameFieldIsValid = NO;
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:self.labelString
                      message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                         self.labelString,
                                      NSLocalizedString(@"You must enter a user name", @"")]
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
    }

    return bUserNameFieldIsValid;
}

// if the field is bad, an appropriate message box is displayed
- (BOOL)fieldsAreValid
{
    BOOL valid = YES;

    // if we are signing up for a new account
    {
        if (self.userNameTextField.text.length < [CoreBridge getMinimumUsernamedLength])
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                    initWithTitle:self.labelString
                          message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                             self.labelString,
                                                             [NSString stringWithFormat:NSLocalizedString(@"Username must be at least %d characters.", @""), [CoreBridge getMinimumUsernamedLength]]]
                         delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
            [alert show];
        }
    }

    return valid;
}

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        [self.activityView startAnimating];
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        [self.activityView stopAnimating];
        self.buttonBlocker.hidden = YES;
    }
}

-(void)scrollTextFieldAboveKeyboard:(UITextField *)textField
{
    
}

- (void)installLeftToRightSwipeDetection
{
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
    gesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:gesture];
}

- (void)exitWithBackButton:(BOOL)bBack
{
//    [self.delegate signupViewControllerDidFinish:self withBackButton:bBack];
}

#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
//    //Get KeyboardFrame (in Window coordinates)
//    if(_activeTextField)
//    {
//        //ABCLog(2,@"Keyboard will show for SignUpView");
//        NSDictionary *userInfo = [notification userInfo];
//        CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//
//        _keyboardFrameOriginY = keyboardFrame.origin.y;
//
//        [self scrollTextFieldAboveKeyboard:_activeTextField];
//    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
//    if(_activeTextField)
//    {
//        //ABCLog(2,@"Keyboard will hide for SignUpView");
//        _activeTextField = nil;
//    }
//    _keyboardFrameOriginY = 0.0;
//    [UIView animateWithDuration:0.35
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^
//                     {
//                         CGRect frame = self.contentView.frame;
//                         frame.origin.y = 0;
//                         self.contentView.frame = frame;
//                     }
//                     completion:^(BOOL finished)
//                     {
//                     }];
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //called when user taps on either search textField or location textField

    _activeTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self next];

    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_activeTextField)
    {
        [_activeTextField resignFirstResponder];
    }
}


#pragma mark - ABC Callbacks

#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // we only use an alert view delegate when we are delaying the exit
    // so we can exit now
    [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    [self back:nil];
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    [self back:nil];
}

@end
