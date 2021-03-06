/*
 *  Copyright (C) 2015-2016 Savoir-faire Linux Inc.
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#import "AccountsVC.h"

// Qt
#import <QItemSelectionModel>
#import <QSortFilterProxyModel>
#import <QtCore/qdir.h>
#import <QtCore/qstandardpaths.h>

// LRC
#import <accountmodel.h>
#import <protocolmodel.h>
#import <account.h>

#import "QNSTreeController.h"
#import "AccGeneralVC.h"
#import "AccMediaVC.h"
#import "AccAdvancedVC.h"
#import "AccSecurityVC.h"
#import "AccRingVC.h"

// We disabled IAX protocol for now, so don't show it to the user
class ActiveProtocolModel : public QSortFilterProxyModel
{
public:
    ActiveProtocolModel(QAbstractItemModel* parent) : QSortFilterProxyModel(parent)
    {
        setSourceModel(parent);
    }
    virtual bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
    {
        return sourceModel()->index(source_row,0,source_parent).flags() & Qt::ItemIsEnabled;
    }
};

@interface AccountsVC ()
@property (assign) IBOutlet NSPopUpButton *protocolList;

@property (assign) IBOutlet NSTabView *configPanels;
@property (retain) IBOutlet NSTabViewItem *generalTabItem;
@property (retain) IBOutlet NSTabViewItem *mediaTabItem;
@property (retain) IBOutlet NSTabViewItem *advancedTabItem;
@property (retain) IBOutlet NSTabViewItem *securityTabItem;
@property (retain) IBOutlet NSTabViewItem *ringTabItem;

@property QNSTreeController *treeController;
@property ActiveProtocolModel* proxyProtocolModel;
@property (assign) IBOutlet NSOutlineView *accountsListView;
@property (assign) IBOutlet NSTabView *accountDetailsView;

@property AccRingVC* ringVC;
@property AccGeneralVC* generalVC;
@property AccMediaVC* audioVC;
@property AccAdvancedVC* advancedVC;
@property AccSecurityVC* securityVC;

@end

@implementation AccountsVC
@synthesize protocolList;
@synthesize configPanels;
@synthesize generalTabItem;
@synthesize mediaTabItem;
@synthesize advancedTabItem;
@synthesize securityTabItem;
@synthesize ringTabItem;
@synthesize accountsListView;
@synthesize accountDetailsView;
@synthesize treeController;
@synthesize proxyProtocolModel;

NSInteger const TAG_CHECK       =   100;
NSInteger const TAG_NAME        =   200;
NSInteger const TAG_STATUS      =   300;
NSInteger const TAG_TYPE        =   400;

- (void)awakeFromNib
{
    treeController = [[QNSTreeController alloc] initWithQModel:&AccountModel::instance()];
    [treeController setAvoidsEmptySelection:NO];
    [treeController setAlwaysUsesMultipleValuesMarker:YES];
    [treeController setChildrenKeyPath:@"children"];

    [accountsListView bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [accountsListView bind:@"sortDescriptors" toObject:treeController withKeyPath:@"sortDescriptors" options:nil];
    [accountsListView bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];

    QObject::connect(&AccountModel::instance(),
                     &QAbstractItemModel::dataChanged,
                     [=](const QModelIndex &topLeft, const QModelIndex &bottomRight) {
                        [accountsListView reloadDataForRowIndexes:
                        [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(topLeft.row(), bottomRight.row() + 1)]
                        columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, accountsListView.tableColumns.count)]];
                     });

    QObject::connect(AccountModel::instance().selectionModel(),
                     &QItemSelectionModel::currentChanged,
                     [=](const QModelIndex &current, const QModelIndex &previous) {
                         [accountDetailsView setHidden:!current.isValid()];
                         if(!current.isValid()) {
                             [accountsListView deselectAll:nil];
                             return;
                         }

                        [treeController setSelectionQModelIndex:current];
                     });


    AccountModel::instance().selectionModel()->clearCurrentIndex();

    proxyProtocolModel = new ActiveProtocolModel(AccountModel::instance().protocolModel());
    QModelIndex qProtocolIdx = AccountModel::instance().protocolModel()->selectionModel()->currentIndex();
    [self.protocolList addItemWithTitle:
                           AccountModel::instance().protocolModel()->data(qProtocolIdx, Qt::DisplayRole).toString().toNSString()];

    self.generalVC = [[AccGeneralVC alloc] initWithNibName:@"AccGeneral" bundle:nil];
    [[self.generalVC view] setFrame:[self.generalTabItem.view frame]];
    [[self.generalVC view] setBounds:[self.generalTabItem.view bounds]];
    [self.generalTabItem setView:self.generalVC.view];

    self.audioVC = [[AccMediaVC alloc] initWithNibName:@"AccMedia" bundle:nil];
    [[self.audioVC view] setFrame:[self.mediaTabItem.view frame]];
    [[self.audioVC view] setBounds:[self.mediaTabItem.view bounds]];
    [self.mediaTabItem setView:self.audioVC.view];

    self.advancedVC = [[AccAdvancedVC alloc] initWithNibName:@"AccAdvanced" bundle:nil];
    [[self.advancedVC view] setFrame:[self.advancedTabItem.view frame]];
    [[self.advancedVC view] setBounds:[self.advancedTabItem.view bounds]];
    [self.advancedTabItem setView:self.advancedVC.view];

    self.securityVC = [[AccSecurityVC alloc] initWithNibName:@"AccSecurity" bundle:nil];
    [[self.securityVC view] setFrame:[self.securityTabItem.view frame]];
    [[self.securityVC view] setBounds:[self.securityTabItem.view bounds]];
    [self.securityTabItem setView:self.securityVC.view];

    self.ringVC = [[AccRingVC alloc] initWithNibName:@"AccRing" bundle:nil];
    [[self.ringVC view] setFrame:[self.ringTabItem.view frame]];
    [[self.ringVC view] setBounds:[self.ringTabItem.view bounds]];
    [self.ringTabItem setView:self.ringVC.view];
}

- (void) dealloc
{
    delete proxyProtocolModel;
}

- (IBAction)moveUp:(id)sender {
    AccountModel::instance().moveUp();
}

- (IBAction)moveDown:(id)sender {
    AccountModel::instance().moveDown();
}

- (IBAction)removeAccount:(id)sender {

    if(treeController.selectedNodes.count > 0) {
        QModelIndex qIdx = [treeController toQIdx:[treeController selectedNodes][0]];
        AccountModel::instance().remove(qIdx);
        AccountModel::instance().save();
    }
}
- (IBAction)addAccount:(id)sender {
    QModelIndex qIdx =  AccountModel::instance().protocolModel()->selectionModel()->currentIndex();

    auto newAccName = [[NSString alloc] initWithFormat:@"%@ account",
                AccountModel::instance().protocolModel()->data(qIdx, Qt::DisplayRole).toString().toNSString(), nil];
    auto acc = AccountModel::instance().add([newAccName UTF8String], qIdx);
    acc->setDisplayName(acc->alias());
    AccountModel::instance().save();
}

- (IBAction)protocolSelectedChanged:(id)sender {

    int index = [sender indexOfSelectedItem];
    QModelIndex proxyIdx = proxyProtocolModel->index(index, 0);
    AccountModel::instance().protocolModel()->selectionModel()->setCurrentIndex(
                proxyProtocolModel->mapToSource(proxyIdx), QItemSelectionModel::ClearAndSelect);

}

- (void) setupSIPPanels
{
    // Start by removing all tabs
    for(NSTabViewItem* item in configPanels.tabViewItems) {
        [configPanels removeTabViewItem:item];
    }

    [configPanels insertTabViewItem:generalTabItem atIndex:0];
    [configPanels insertTabViewItem:mediaTabItem atIndex:1];
    [configPanels insertTabViewItem:advancedTabItem atIndex:2];
    [configPanels insertTabViewItem:securityTabItem atIndex:3];
}

- (void) setupIAXPanels
{
    // Start by removing all tabs
    for(NSTabViewItem* item in configPanels.tabViewItems) {
        [configPanels removeTabViewItem:item];
    }

    [configPanels insertTabViewItem:generalTabItem atIndex:0];
    [configPanels insertTabViewItem:mediaTabItem atIndex:1];
}

- (void) setupRINGPanels
{
    // Start by removing all tabs
    for(NSTabViewItem* item in configPanels.tabViewItems) {
        [configPanels removeTabViewItem:item];
    }

    [configPanels insertTabViewItem:ringTabItem atIndex:0];
    [configPanels insertTabViewItem:mediaTabItem atIndex:1];
    [configPanels insertTabViewItem:advancedTabItem atIndex:2];

}

- (IBAction)toggleAccount:(NSButton*)sender {
    NSInteger row = [accountsListView rowForView:sender];
    auto accountToToggle = AccountModel::instance().getAccountByModelIndex(AccountModel::instance().index(row));
    accountToToggle->setEnabled(sender.state);
    accountToToggle << Account::EditAction::SAVE;
}

#pragma mark - NSOutlineViewDelegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
    return YES;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    return [outlineView makeViewWithIdentifier:@"HoverRowView" owner:nil];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSTableView* result = [outlineView makeViewWithIdentifier:@"AccountView" owner:self];

    QModelIndex qIdx = [treeController toQIdx:((NSTreeNode*)item)];
    if(!qIdx.isValid())
        return result;

    NSTextField* nameLabel = [result viewWithTag:TAG_NAME];
    NSTextField* stateLabel = [result viewWithTag:TAG_STATUS];
    NSButton* checkButton = [result viewWithTag:TAG_CHECK];
    NSTextField* typeLabel = [result viewWithTag:TAG_TYPE];

    auto account = AccountModel::instance().getAccountByModelIndex(qIdx);
    auto humanState = account->toHumanStateName();

    [nameLabel setStringValue:account->alias().toNSString()];
    [stateLabel setStringValue:humanState.toNSString()];
    [checkButton setHidden:AccountModel::instance().ip2ip()->index() == qIdx];

    switch (account->protocol()) {
        case Account::Protocol::SIP:
            [typeLabel setStringValue:@"SIP"];
            break;
        case Account::Protocol::IAX:
            [typeLabel setStringValue:@"IAX"];
            break;
        case Account::Protocol::RING:
            [typeLabel setStringValue:@"RING"];
            break;
        default:
            break;
    }

    switch (account->registrationState()) {
        case Account::RegistrationState::READY:
            [stateLabel setTextColor:[NSColor colorWithCalibratedRed:116/255.0 green:179/255.0 blue:93/255.0 alpha:1.0]];
            break;
        case Account::RegistrationState::TRYING:
            [stateLabel setTextColor:[NSColor redColor]];
            break;
        case Account::RegistrationState::UNREGISTERED:
            [stateLabel setTextColor:[NSColor blackColor]];
            break;
        case Account::RegistrationState::ERROR:
            [stateLabel setTextColor:[NSColor redColor]];
            break;
        default:
            [stateLabel setTextColor:[NSColor blackColor]];
            break;
    }

    [checkButton setState:qIdx.data(Qt::CheckStateRole).value<BOOL>()];

    return result;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    // ask the tree controller for the current selection
    if([[treeController selectedNodes] count] > 0) {
        auto qIdx = [treeController toQIdx:[treeController selectedNodes][0]];
        //Update details view
        auto acc = AccountModel::instance().getAccountByModelIndex(qIdx);
        AccountModel::instance().selectionModel()->setCurrentIndex(qIdx, QItemSelectionModel::ClearAndSelect);

        switch (acc->protocol()) {
            case Account::Protocol::SIP:
                [self setupSIPPanels];
                break;
            case Account::Protocol::IAX:
                [self setupIAXPanels];
                break;
            case Account::Protocol::RING:
                [self setupRINGPanels];
                break;
            default:
                break;
        }

        [self.accountDetailsView setHidden:NO];
    } else {
        AccountModel::instance().selectionModel()->clearCurrentIndex();
    }
}

#pragma mark - NSMenuDelegate methods

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    QModelIndex proxyIdx = proxyProtocolModel->index(index, 0);
    QModelIndex qIdx = AccountModel::instance().protocolModel()->index(proxyProtocolModel->mapToSource(proxyIdx).row());
    [item setTitle:qIdx.data(Qt::DisplayRole).toString().toNSString()];

    return YES;
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
    return proxyProtocolModel->rowCount();
}

@end
