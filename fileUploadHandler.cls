public class fileUploadHandler {
    public static Map<String, List<String>> fileToFolderMap = new Map<String, List<String>>{
        'Application' => new List<String>{ 'Application Information', 'Processor License Application' },
        'Applicant' => new List<String>{ 'Application Information' },
        'Citation' => new List<String>{ 'Citations' },
        'Letter' => new List<String>{ 'Letters of concern' },
        'Warning' => new List<String>{ 'Warning Letters' },
        'Inspection' => new List<String>{ 'Inspection Reports' },
        'Visit' => new List<String>{ 'Inspection Reports' },
        'GMP' => new List<String>{ 'GMP Certificate' },
        'License' => new List<String>{ 'Processor License' },
        'Site' => new List<String>{ 'Site Map' },
        'Map' => new List<String>{ 'Site Map', 'Histories And Maps' },
        'Location' => new List<String>{ 'Site Map' },
        'Retail' => new List<String>{ 'Retail Permit Application' },
        'Label' => new List<String>{ 'Label' },
        'Sales Advertising' => new List<String>{ 'Addtional' },
        'History' => new List<String>{ 'Histories And Maps' },
        'Histories' => new List<String>{ 'Histories and Maps' },
        'Seed' => new List<String>{ 'Pest Control' },
        'Billing' => new List<String>{ 'Billing' },
        'Certificate' => new List<String>{ 'Letters and Certificate' },
        'Review' => new List<String>{ 'Reviews' },
        'Sample' => new List<String>{ 'Sample' },
        'Addendum' => new List<String>{ 'Addendum' },
        'Ammonia' => new List<String>{ 'Equipment and Cleaning' },
        'Inspection Appointment' => new List<String>{ 'Application and Narrative' },
        'Fumigation' => new List<String>{ 'Pest Control' },
        'NAQS' => new List<String>{ 'Export' },
        'TM-' => new List<String>{ 'Export' },
        'Transcation' => new List<String>{ 'Export' },
        'Interview' => new List<String>{ 'Inspection' },
        'Meeting' => new List<String>{ 'Inspection' },
        'Livestock' => new List<String>{ 'Feed Livestock' },
        'Poultry' => new List<String>{ 'Feed Livestock' },
        'Product' => new List<String>{ 'Product' },
        'Supplier' => new List<String>{ 'Product' }
    };
    public static list<string> statusNotToUploadList = new list<String>{
            'Draft','Payment Pending', 'Payment Requested', 'Payment Received', 'Pending Application Fee Payment','Fee Estimate Pending'
        };
    public static void sendFileToGD(Id linkedEntityId, ContentVersion fileContentVersion){
        system.debug('fileUploadHandler.sendFileToGD');
        //Get object name to get the shared record id
        sobjectType parentSObjectType = linkedEntityId.getSobjectType();
        String parentSObjectName = parentSObjectType.getDescribe().getLabel();
        parentSObjectName = parentSObjectName.toLowerCase();
        
        String driveId = googleDriveUtility.getSharedDriveId(parentSObjectName);
        system.debug('driveId -> ' + driveId);
        
        String query = '';
        if(parentSObjectName.contains('cannabis') == true){
            String cannabisQuery = 'SELECT Id, Name, ApplicationCategory__c, RelatedCannabisApplication__c FROM ' + parentSObjectType + ' WHERE ID = :linkedEntityId';
            query = cannabisQuery;
        }else if(parentSObjectName.contains('hemp') == true){
            String hempQuery = 'SELECT Id, Name, RecordTypeId, RelatedHempApplication__c, ChangeRequestStatus__c, Status__c FROM ' + parentSObjectType + ' WHERE ID = :linkedEntityId';
            query = hempQuery;
        }else if(parentSObjectName.contains('organics') == true){
            String organicsQuery = 'SELECT Id, Name, TypeOfApplication__c, RelatedOrganicsApplication__c FROM '  + parentSObjectType + ' WHERE ID = :linkedEntityId';
            query = organicsQuery;
        }
        
        sobject parentObjectRecord = database.query(query);
        
        Id recordTypeId = (Id) parentObjectRecord.get('recordTypeId');
        String applicationStatus = String.valueof(parentObjectRecord.get('Status__c'));
        String changeRequstStatus = String.valueof(parentObjectRecord.get('ChangeRequestStatus__c'));
        String recordName = String.valueOf(parentObjectRecord.get('Name'));
        system.debug('applicationStatus -> ' + applicationStatus);
        system.debug('changeRequstStatus -> ' + changeRequstStatus);
        system.debug('recordName -> ' + recordName);
        system.debug('recordTypeId -> ' + recordTypeId);
        
        if(statusNotToUploadList.contains(applicationStatus) != true){
            system.debug('FILES WILL BE MOVED');
            system.debug('applicationStatus -> ' + applicationStatus);
        }else{
            system.debug('FILES WILL NOT BE MOVED');
            system.debug('applicationStatus -> ' + applicationStatus);
            return;
        }
        
        recordType rt = [select Name from RecordType where id = :recordTypeId];
        String recordTypeName = rt.Name;
        recordTypeName = recordTypeName.toLowerCase();
        Boolean mainApplicationFlag = true;          //If true run logic for main application, else run logic for change request
        ID BLAId = null;
        
        if(recordTypeName.contains('change') != true){
            mainApplicationFlag = true;
            //Get BLA assoicated with that record if record is not change request record
            system.debug('MAIN Record -> ' + String.valueOf(parentObjectRecord.get('Name')));
            String BLAQuery = 'SELECT Id, LicenseType.Name FROM BusinessLicenseApplication WHERE ';
            
            if(parentSObjectName.contains('cannabis') == true){
                BLAQuery += 'Cannabis_Application__c = :linkedEntityId';
                
            }else if(parentSObjectName.contains('hemp') == true){
                BLAQuery += 'Hemp_Application__c = :linkedEntityId';
            }else if(parentSObjectName.contains('organics') == true){
                BLAQuery += 'Organics_Application__c = :linkedEntityId';
            }
            system.debug('BLAQuery -> ' + BLAQuery);
            sobject BLARecord = database.query(BLAquery);
            BLAId = (ID) String.valueOf(BLARecord.get('Id'));
            system.debug('BLAId -> ' + BLAId);
        }else{
            mainApplicationFlag = false;
            //Get BLA associated with main application of change request reocrd
            system.debug('CR Record -> ' + String.valueOf(parentObjectRecord.get('Name')));
            if(changeRequstStatus == 'Approved'){
                system.debug('FILES WILL BE MOVED');
                system.debug('applicationStatus -> ' + applicationStatus);
            }else{
                system.debug('FILES WILL NOT BE MOVED');
                system.debug('applicationStatus -> ' + applicationStatus);
                return;
            }
            ID mainAppId = null;
            String mainAppQuery = 'SELECT Id, LicenseType.Name FROM ' + parentSObjectType + ' WHERE ';            
            if(parentSObjectName.contains('cannabis') == true){
                mainAppQuery += 'RelatedCannabisApplication__c = :linkedEntityId';
                system.debug('BLAQuery -> ' + mainAppQuery);
                sobject mainAppRecord = database.query(mainAppQuery);
                mainAppId = String.valueOf(mainAppRecord.get('RelatedCannabisApplication__c'));
            }else if(parentSObjectName.contains('hemp') == true){
                mainAppQuery += 'Hemp_Application__c = :linkedEntityId';
                system.debug('BLAQuery -> ' + mainAppQuery);
                sobject mainAppRecord = database.query(mainAppQuery);
                mainAppId = String.valueOf(mainAppRecord.get('RelatedHempApplication__c'));
            }else if(parentSObjectName.contains('organics') == true){
                mainAppQuery += 'RelatedOrganicsApplication__c = :linkedEntityId';
                system.debug('BLAQuery -> ' + mainAppQuery);
                sobject mainAppRecord = database.query(mainAppQuery);
                mainAppId = String.valueOf(mainAppRecord.get('RelatedOrganicsApplication__c'));
            }
            if(mainAppId != null){
                
                String BLAQuery = 'SELECT Id, LicenseType.Name FROM BusinessLicenseApplication WHERE ';
                
                if(parentSObjectName.contains('cannabis') == true){
                    BLAQuery += 'Cannabis_Application__c = :mainAppId';
                }else if(parentSObjectName.contains('hemp') == true){
                    BLAQuery += 'Hemp_Application__c = :mainAppId';
                }else if(parentSObjectName.contains('organics') == true){
                    BLAQuery += 'Organics_Application__c = :mainAppId';
                }
                system.debug('BLAQuery -> ' + BLAQuery);
                sobject BLARecord = database.query(BLAquery);
                BLAId = (ID) String.valueOf(BLARecord.get('Id'));
                system.debug('BLAId -> ' + BLAId);
            }
        }
        
        
        //Get folder records from Google_Drive_Folder__c object associated with BLA
        if(BLAId != null){
            if(mainApplicationFlag == true){
                system.debug('BLAID -> ' + BLAId);
                map<String, String> folderNameToIdMap = new map<String, String>();
                for(GoogleDrive_Folder__c GDriveFolder: [select Business_License_Application__r.Name, License_Type__c, FolderId__c, Name__c from GoogleDrive_Folder__c where Business_License_Application__c = :BLAId and isfileuploaded__c = false]){
                    folderNameToIdMap.put(GDriveFolder.name__c, GDriveFolder.folderId__c);
                }
                system.debug(json.serializePretty(folderNameToIdMap));
                String defaultFolderName = 'Default';
                String defaultFolderId = folderNameToIdMap.get(defaultFolderName);
                system.debug('defaultFolderName => ' + defaultFolderName);
                system.debug('defaultFolderId => ' + defaultFolderId);
                
                String folderName = null; // Initialize to null before the loop
                system.debug('fileContentVersion.title -> ' + fileContentVersion.title);
                for(String fileName: fileToFolderMap.keySet()){
                    if(fileContentVersion.title.contains(fileName)){
                        list<String> possibleFolders = fileToFolderMap.get(fileName);
                        for(String folder: possibleFolders){
                            if(folderNameToIdMap.containsKey(folder) == true){
                                folderName = folder;
                            }
                        }
                        break;
                    }
                }
                String folderId = (folderName != null && folderNameToIdMap.get(folderName) != null) ? folderNameToIdMap.get(folderName) : defaultFolderId;
                system.debug('folderId -> ' + folderId);
                if (folderId != null) {
                    system.debug('folderId -> ' + folderId);
                    system.debug('SENDING FILE TO GDRIVE');
                    googleDriveUtility.sendFilesToGD(folderId, fileContentVersion, BLAId, driveId);
                }
            }else{
                //Run logic for change request
                String changeReqName = '%' + recordName.split('-')[1] + '%';
                GoogleDrive_Folder__c gdriveFolderRecord = [select Business_License_Application__r.Name, License_Type__c, FolderId__c, Name__c from GoogleDrive_Folder__c where Business_License_Application__c =:BLAId and Name__c LIKE :changeReqName LIMIT 1];
                String folderId = gdriveFolderRecord.FolderId__c;
                googleDriveUtility.sendFilesToGD(folderId, fileContentVersion, BLAId, driveId);
            }
        }
    }
}
