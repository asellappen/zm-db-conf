#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2008, 2009, 2010, 2013, 2014 Zimbra, Inc.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 

use strict;
use Migrate;
my $concurrent = 10;

my @groups = Migrate::getMailboxGroups();
my $sqlGroupsWithSmallMailitem = <<_SQL_;
SELECT table_schema FROM information_schema.columns
WHERE table_name = 'mail_item' AND column_name = 'size' AND data_type = 'int'
ORDER BY table_schema;
_SQL_
my %mailItemGroups  = map { $_ => 1 } Migrate::runSql($sqlGroupsWithSmallMailitem);

my $sqlGroupsWithSmallRevisions = <<_SQL_;
SELECT table_schema FROM information_schema.columns
WHERE table_name = 'revision' AND column_name = 'size' AND data_type = 'int'
ORDER BY table_schema;
_SQL_
my %revisionGroups = map { $_ => 1 } Migrate::runSql($sqlGroupsWithSmallRevisions);

Migrate::verifySchemaVersion(49);

my @sql = ();
foreach my $group (@groups) {
  if (exists $mailItemGroups{$group}) {
    my $sql = <<_MAILITEM_SQL_;
ALTER TABLE $group.mail_item MODIFY COLUMN size BIGINT UNSIGNED NOT NULL;
_MAILITEM_SQL_
    push(@sql, $sql);
  } 
  if (exists $revisionGroups{$group}) {
    my $sql = <<_REVISION_SQL_;
ALTER TABLE $group.revision MODIFY COLUMN size BIGINT UNSIGNED NOT NULL;
_REVISION_SQL_
    push(@sql, $sql);
  } 
}
Migrate::runSqlParallel($concurrent, @sql);

Migrate::updateSchemaVersion(49, 50);

exit(0);

#####################
