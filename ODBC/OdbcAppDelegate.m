//
//  OdbcAppDelegate.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-10.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcAppDelegate.h"

#import <Odbc.h>

NSString * PersistentStoreType  = @"OdbcStore";
NSString * PersistentStoreClass = @"OdbcStore";

@interface OdbcAppDelegate ()

@end

@implementation OdbcAppDelegate;

@synthesize persistentStoreType;
@synthesize persistentStoreClass;
@synthesize persistentStoreUrl;

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

@synthesize productName;
@synthesize applicationFilesDirectory;
//
// Nothing to do right now
//
- (void) applicationDidFinishLaunching : (NSNotification *) aNotification {
    
}
//
// Returns persistent store type
//
- (NSString *) persistentStoreType {
    
    return PersistentStoreType;
}
//
// Returns persistent store class
//
- (NSString *) persistentStoreClass {
    
    return PersistentStoreClass;
}
//
// Returns persistent store url
//
- (NSURL *) persistentStoreUrl {
    
    if (self->persistentStoreUrl) return self->persistentStoreUrl;
    
    if (self.persistentStoreClass) {
        
        RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,"Method 'persistentStoreUrl should be implemented by the application");
    }
    
    
    NSString * storeFileName = [NSString stringWithFormat : @"%@.storedata",self.productName];
    
    self->persistentStoreUrl = [self.applicationFilesDirectory URLByAppendingPathComponent : storeFileName];
    
    return self->persistentStoreUrl;
}
//
// Returns product name
//
- (NSString *) productName {
    
    if (self->productName) return self->productName;
    
    NSDictionary * bundleInfo = [[NSBundle mainBundle] infoDictionary];
    
    self->productName = [bundleInfo objectForKey : @"CFBundleName"];
    
    return self->productName;
}
//
// Reloads data
//
- (IBAction) reloadAction : (id) sender {
    
    NSError * error = nil;
    
    NSArray * entities = self.managedObjectModel.entities;
    
    for (NSEntityDescription * ed in entities) {
        
        NSFetchRequest * fr = [NSFetchRequest fetchRequestWithEntityName : ed.name];
        
        NSArray * objects = [self.managedObjectContext executeFetchRequest : fr error : &error];
        
        if (! objects) {
            
            [[NSApplication sharedApplication] presentError : error];
            
            [[NSApplication sharedApplication] terminate : self];
        }
        
        NSObjectController * controller = [self controllerForEntity : ed.name];
        
        [controller setContent : objects];
    }
    
    NSSet * objectsSet = self.managedObjectContext.registeredObjects;
    
    for (NSManagedObject * object in objectsSet) {
        
        [self.managedObjectContext refreshObject : object mergeChanges : YES];
    }
}
//
// Should return a controller given entity name
//
- (NSObjectController *) controllerForEntity : (NSString *) entityName {
    
    RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,"Method controllerForEntity should be implemented by the application");
    
    return nil;
}
//
//------------------------------------------------------------------------------
// Code below has been generated by XCode and modified by me.
//------------------------------------------------------------------------------
//
// Returns the managed object context for the application.
//
- (NSManagedObjectContext *) managedObjectContext {
    
    if (self->managedObjectContext) return self->managedObjectContext;
    
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    
    self->managedObjectContext = [NSManagedObjectContext new];
    
    [self->managedObjectContext setPersistentStoreCoordinator : coordinator];
    
    [self->managedObjectContext setStalenessInterval : 0.0];
    
    return self->managedObjectContext;
}
//
// Returns the persistent store coordinator for the application.
//
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (self->persistentStoreCoordinator) return self->persistentStoreCoordinator;
    //
    // Get managed object model
    //
    NSManagedObjectModel * mom = self.managedObjectModel;
    
    NSError * error = nil;
    //
    // Using a method to get URL instead of a constant as it was in XCode generated code
    //
    NSURL * url = self.persistentStoreUrl;
    //
    // Register custom store type
    //
    if (self.persistentStoreType && self.persistentStoreClass) {
        
        [NSPersistentStoreCoordinator registerStoreClass : NSClassFromString (self.persistentStoreClass)
                                            forStoreType : self.persistentStoreType];
    }
    //
    // Create persisten store coordinator
    //
    NSPersistentStoreCoordinator * coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel : mom];
    //
    // Using global variable PersistentStoreType instead of a constant as it was in XCode generated code
    //
    if (! [coordinator addPersistentStoreWithType : self.persistentStoreType
                                    configuration : nil
                                              URL : url
                                          options : nil
                                            error : &error]) {
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return nil;
    }
    
    self->persistentStoreCoordinator = coordinator;
    
    return self->persistentStoreCoordinator;
}
//
// Creates if necessary and returns the managed object model for the application.
//
- (NSManagedObjectModel *) managedObjectModel {
    
    if (self->managedObjectModel) return self->managedObjectModel;
    //
    // Using bundle info instead of a constant as it was in XCode generated code
    //
    NSString * modelFileName = [self productName];
	
    NSURL * modelURL = [[NSBundle mainBundle] URLForResource : modelFileName withExtension : @"momd"];
    
    self->managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL : modelURL];
    
    if (! self->managedObjectModel) {
        
        NSString * desc = [NSString stringWithFormat : @"Cannot create managed object model from url '%@'",modelURL];
        
        NSDictionary * dict = @{NSLocalizedDescriptionKey : desc};
        
        NSError * error = [NSError errorWithDomain : @"Managed Object Model" code : 0 userInfo : dict];
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return nil;
    }
    
    return self->managedObjectModel;
}
//
// Returns the directory the application uses to store the Core Data store file.
//
// Note that this method is not used when running against 'OdbcStore'.
//
- (NSURL *) applicationFilesDirectory {
    
    if (self->applicationFilesDirectory) return self->applicationFilesDirectory;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSURL * appSupportURL =
    
    [[fileManager URLsForDirectory : NSApplicationSupportDirectory inDomains : NSUserDomainMask] lastObject];
    
    NSError * error = nil;
    //
    // Get NSUrlIsDirectoryKey property for the url
    //
    NSDictionary * properties = [appSupportURL resourceValuesForKeys : @[NSURLIsDirectoryKey] error : &error];
    //
    // Check if we got any properties
    //
    if (!properties) {
        //
        // We did not - check if path exsists
        //
        if ([error code] == NSFileReadNoSuchFileError) {
            //
            // It does not - try to create the directory
            //
            bool ok = [fileManager createDirectoryAtPath : [appSupportURL path]
                             withIntermediateDirectories : YES
                                              attributes : nil
                                                   error : &error];
            
            if (! ok) {
                //
                // Could not create directory
                //
                [[NSApplication sharedApplication] presentError : error];
                
                [[NSApplication sharedApplication] terminate : self];
                
                return nil;
            }
            
        } else {
            //
            // It was some other error
            //
            [[NSApplication sharedApplication] presentError : error];
            
            [[NSApplication sharedApplication] terminate : self];
            
            return nil;
        }
        
    } else {
        //
        // Check if url is directory
        //
        if (! [properties[NSURLIsDirectoryKey] boolValue]) {
            //
            // No it is not
            //
            NSString * failureDescription =
            
            [NSString stringWithFormat : @"Expected a folder to store application data, found a file (%@).",
                                         [appSupportURL path]];
            
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];
            
            [dict setValue : failureDescription forKey : NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain : @"Applcation Support Directory" code : 101 userInfo : dict];
            
            [[NSApplication sharedApplication] presentError : error];
            
            [[NSApplication sharedApplication] terminate : self];
            
            return nil;
        }
    }
    
    self->applicationFilesDirectory = appSupportURL;
    
    return self->applicationFilesDirectory;
}
//
// Returns the NSUndoManager for the application.
//
- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window {
    
    return [[self managedObjectContext] undoManager];
}
//
// Performs the save action for the application.
//
- (IBAction) saveAction : (id) sender {
    
    NSError * error = nil;
    
    if (! self->managedObjectModel) return;
    
    if (! [[self managedObjectContext] commitEditing]) {
        
        error = [NSError errorWithDomain : @"Commit Editing"
                                    code : 0
                                userInfo : @{NSLocalizedDescriptionKey : @"Cannot commit editing"}];
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return;
    }
    
    if (! [[self managedObjectContext] hasChanges]) return;
    
    if (! [[self managedObjectContext] save : &error]) {
        
        [[NSApplication sharedApplication] presentError : error];
        
        [[NSApplication sharedApplication] terminate : self];
        
        return;
    }
}
//
// Called when application is about to terminate
//
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) sender {
    //
    // Save changes in the application's managed object context before the application terminates.
    //
    [self saveAction : self];
    
    return NSTerminateNow;
}

@end
