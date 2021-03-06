//
//  OdbcDocument.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-11-14.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "OdbcDocument.h"

#import "Odbc.h"

@interface OdbcDocument () {
    
    bool closing;
}

@property bool closing;

@end


@implementation OdbcDocument

@synthesize closing;
@synthesize persistentStoreType;
@synthesize persistentStoreClass;
@synthesize persistentStoreUrl;

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

@synthesize productName;
@synthesize modelFileName;
//
// Initialize object
//
- (OdbcDocument *) init {
    
    self = [super init];
    
    if (! self) return self;
    
    self->closing = NO;
    
    return self;
}
//
// Returns persistent store type
//
- (NSString *) persistentStoreType {
    
    return @"OdbcStore";
}
//
// Returns persistent store class
//
- (NSString *) persistentStoreClass {
    
    return @"OdbcStore";
}
//
// Returns persistent store url
//
- (NSURL *) persistentStoreUrl {
    
    if (self->persistentStoreUrl) return self->persistentStoreUrl;
            
    RAISE_ODBC_EXCEPTION (__PRETTY_FUNCTION__,"Method 'persistentStoreUrl should be implemented by the document");
    
    return nil;
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
// Reloads data and merges changes
//
- (IBAction) reloadAction : (id) sender {
    
    [self reloadMerge : NO];
}
//
// Reloads data with or without merge
//
- (void) reloadMerge : (bool) merge {
    
    NSMutableDictionary * oldDict = [self currentObjectsDict];
    
    [self commit];
    
    [self fetchObjectsIntoContext : self.managedObjectContext];
    
    NSManagedObjectContext * newContext = [self createNewContext];
    
    NSSet * newSet = [self fetchObjectsIntoContext : newContext];
    
    NSMutableSet * delSet = [NSMutableSet new];
    
    NSMutableSet * insSet = [NSMutableSet new];
    
    NSMutableSet * updSet = [NSMutableSet new];
    
    for (NSManagedObject * newObj in newSet) {
        
        NSManagedObject * oldObj = [oldDict objectForKey : newObj.objectID];
        
        if (oldObj) {
            
            [self.managedObjectContext refreshObject : oldObj mergeChanges : merge];
            
            [updSet addObject : oldObj];
            
            [oldDict removeObjectForKey : oldObj.objectID];
            
        } else {
            
            [insSet addObject : newObj];
        }
    }
    
    for (NSManagedObject * oldObj in oldDict.allValues) {
        
        [self.managedObjectContext deleteObject : oldObj];
        
        [delSet addObject : oldObj];
    }
    
    [self.managedObjectContext processPendingChanges];
    
    NSDictionary * userInfo = @{NSDeletedObjectsKey     : delSet,
                                NSInsertedObjectsKey    : insSet,
                                NSUpdatedObjectsKey     : updSet,
                                @"managedObjectContext" : self.managedObjectContext};
    
    NSNotification * notif = [NSNotification notificationWithName : NSManagedObjectContextObjectsDidChangeNotification
                                                           object : self.managedObjectContext
                                                         userInfo : userInfo];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc postNotification : notif];
}
//
// Return predicate for given entity
//
- (NSPredicate *) predicateForEntity : (NSEntityDescription *) entity {
    
    return nil;
}
//
// Fetch and return objects into context
//
- (NSSet *) fetchObjectsIntoContext : (NSManagedObjectContext *) moc {
    
    NSError * error = nil;
    
    NSMutableSet * set = [NSMutableSet new];
    
    NSArray * entities = self.managedObjectModel.entities;
    
    for (NSEntityDescription * ed in entities) {
        
        NSFetchRequest * fr = [NSFetchRequest fetchRequestWithEntityName : ed.name];
        
        NSPredicate * pred = [self predicateForEntity : ed];
        
        if (pred) fr.predicate = pred;
        
        NSArray * objs = [moc executeFetchRequest : fr error : &error];
        
        if (objs == nil) {
            
            [[NSApplication sharedApplication] presentError : error];
            
            return nil;
        }
        
        [set addObjectsFromArray : objs];
    }
    
    return set;
}
//
// Return dictionary of current objects
//
- (NSMutableDictionary *) currentObjectsDict {
    
    NSMutableDictionary * dict = [NSMutableDictionary new];
    
    NSSet * set = self.managedObjectContext.registeredObjects;
    
    for (NSManagedObject * obj in set) {
        
        [dict setObject : obj forKey : obj.objectID];
    }
    
    return dict;
}
//
// Commits current transaction
//
- (void) commit {
    
    NSSet * delSet = [NSSet new];
    
    NSSet * insSet = [NSSet new];
    
    NSSet * updSet = [NSSet new];
    
    NSSet * locSet = [NSSet new];
    
    NSSaveChangesRequest * req = [[NSSaveChangesRequest alloc] initWithInsertedObjects : insSet
                                                                        updatedObjects : updSet
                                                                        deletedObjects : delSet
                                                                         lockedObjects : locSet];
    
    NSPersistentStore * store = self.managedObjectContext.persistentStoreCoordinator.persistentStores[0];
    
    if ([store isKindOfClass : [NSIncrementalStore class]]) {
        
        NSError * error = nil;
        
        [((NSIncrementalStore *)store) executeRequest : req withContext : self.managedObjectContext error : &error];
        
        if (error) {
            
            [[NSApplication sharedApplication] presentError : error];
            
            return;
        }
    }
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
    
    self->managedObjectContext = [self createNewContext];
    
    return self->managedObjectContext;
}
//
// Create and return new context
//
- (NSManagedObjectContext *) createNewContext {
    
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    
    NSManagedObjectContext * moc = [NSManagedObjectContext new];
    
    [moc setPersistentStoreCoordinator : coordinator];
    
    [moc setStalenessInterval : 0.0];
    
    NSMergePolicy * policy = [[NSMergePolicy alloc] initWithMergeType : NSMergeByPropertyObjectTrumpMergePolicyType];
    
    moc.mergePolicy = policy;
    
    return moc;
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
    NSString * fileName = self.modelFileName;
	
    NSURL * modelURL = [[NSBundle mainBundle] URLForResource : fileName withExtension : @"momd"];
    
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
// Returns model file name
//
- (NSString *) modelFileName {
    
    return [self productName];
}
//
// Returns the NSUndoManager for the application.
//
- (NSUndoManager *) windowWillReturnUndoManager : (NSWindow *) window {
    
    return [[self managedObjectContext] undoManager];
}
//
// Saves data in database and reloads all data again.
//
- (IBAction) saveAction : (id) sender {
    
    [self saveReload : YES];
}
//
// Save data in database with or without reload
//
- (void) saveReload : (bool) reload {
    
    NSError * error = nil;
    
    if (! self->managedObjectModel || ! self->managedObjectContext || ! self->persistentStoreCoordinator) return;
    
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
        
        if ([error.domain isEqualToString : @"Transaction rolled back"]) {
            
            NSString * desc = @"The database was modified during your work. "
            "Your transaction was rolled back in order to keep database integrity. "
            "Your data will be reloaded from database. "
            "Press OK button now to continue.";
            
            NSDictionary * userInfo = [NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey];
            
            NSError * err = [NSError errorWithDomain : @"Transaction rolled back" code : 0 userInfo : userInfo];
            
            [[NSApplication sharedApplication] presentError : err];
            
            if (! self.closing) [self reloadMerge : NO];
            
            return;
        }
        
        [[NSApplication sharedApplication] presentError : error];
        
        return;
    }
    
    if (reload) {
        
        [self reloadMerge : NO];
    }
}

@end
