@interface QQBaseChatViewController : UIViewController
- (void)sendSpecialText:(NSString *)text;
@end

@interface QQChatViewController : QQBaseChatViewController
@end

@interface QQChatViewTable : UITableView
@property(assign, nonatomic) QQChatViewController *supViewController;
@end

@interface QQChatCellModel : NSObject
@property(retain, nonatomic) NSString* nick;
@property(retain, nonatomic) NSString* content;
@property(assign) BOOL isSelf;
@property(retain, nonatomic) NSString* uin;
@end

@interface QQChatViewCell : UITableViewCell
@property(retain, nonatomic) QQChatCellModel* data;
@property(retain, nonatomic) NSString* nick;
@end

@interface QQTimeModel : NSObject
@property(assign, nonatomic) double time;
@end

static NSMutableDictionary *dictionary;

%hook QQChatViewTable
- (void)addObject:(id)object // QQTimeModel or QQChatCellModel
{
	%orig;

	QQChatViewController *controller = [self supViewController];

	if ([object isKindOfClass:NSClassFromString(@"QQTimeModel")])
	{
		NSDate *current = [NSDate dateWithTimeIntervalSince1970:[object time]];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"HH"];
		NSString *date = [formatter stringFromDate:current];
		[formatter release];

		if ([date intValue] >= 1 && [date intValue] <= 5)
		{
			NSString *goToBedMessage = [[NSString alloc] initWithFormat:@"现在都凌晨%@点多了，早点休息吧，身体是革命的本钱啊！", date];
			[controller sendSpecialText:goToBedMessage];
			[goToBedMessage release];
		}
	}
	else if ([object isKindOfClass:NSClassFromString(@"QQChatCell")] || [object isKindOfClass:NSClassFromString(@"QQChatCellModel")])
	{
		if (![object isSelf]) // get rid of circle
		{
			NSString *content = [object content];
			NSString *nick = [object nick];

			if ([content rangeOfString:@"skua"].location != NSNotFound)
			{
				if ([nick isEqualToString:@"大名狗剩"])
				{
					NSString *assistantMessage = [[NSString alloc] initWithString:@"好的主人。"];
					[controller sendSpecialText:assistantMessage];
					[assistantMessage release];
				}
				else
				{
					NSString *jokeMessage = [[NSString alloc] initWithFormat:@"@%@ ，叫我干嘛？不理你~", nick];
					[controller sendSpecialText:jokeMessage];
					[jokeMessage release];
				}
			}
			else
			{
				for (NSString *message in [dictionary allKeys])
				{
					if ([content rangeOfString:message].location != NSNotFound)
					{
						NSString *replyMessage = [[NSString alloc] initWithFormat:@"你好@%@ ，%@", nick, [dictionary objectForKey:message]];
						[controller sendSpecialText:replyMessage];
						[replyMessage release];
						break;
					}
				}
			}
		}
	}
}
%end

__attribute__((always_inline)) __attribute__((visibility("hidden")))
static inline void CreateSkuaDatabase(void)
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filePath = [documentsDirectory stringByAppendingString:@"/skua.plist"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		NSString *welcomMessage = [[NSString alloc] initWithString:@"欢迎加入iOS应用逆向工程官方群。你可以先跟大家打个招呼，也可以去问题最集中的论坛ios.com转转。Have fun :)"];
		NSString *replyMessage = [[NSString alloc] initWithString:@"iOS应用逆向工程Q群小秘书正在为您服务。有技术问题？QQ消息流动太快，留不住有用信息，大家现在可能都在忙，很可能遗漏这个问题。请您整理一下问题的来龙去脉，附带必要的调试信息，去我们的论坛iosre.com发帖，谢谢！"];
		[dictionary release];
		dictionary = nil;
		dictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:welcomMessage, @"已加入群", replyMessage, @"求解决", replyMessage, @"求解答", replyMessage, @"为什么", replyMessage, @"么？", replyMessage, @"吗？", replyMessage, @"不？", nil]; // object: reply key: keyword
		[dictionary writeToFile:filePath atomically:YES];
		[welcomMessage release];
		[replyMessage release];
	}
	else
	{
		[dictionary release];
		dictionary = nil;
		dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
	}
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	CreateSkuaDatabase();
	[pool drain];
}
