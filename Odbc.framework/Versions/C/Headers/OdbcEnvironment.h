//
//  OdbcEnvironment.h
//  OdbcTest1
//
//  Created by Mikael Hakman on 2013-09-03.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OdbcException.h"

@interface OdbcEnvironment : NSObject {
    
    @protected
    
    void * henv;
}

@property (readonly) void * henv;

+ (OdbcEnvironment *) sharedInstance;

@end
