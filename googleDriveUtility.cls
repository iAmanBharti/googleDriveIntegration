public class googleDriveUtility {
    public list<GoogleDrive_Folder__c> filesUploadedToDriveGDRecordList = new list<GoogleDrive_Folder__c>();
    public List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
    public set<id> contentDocsToDeleteId = new set<Id>();
    public static void sendFilesToGD(String folderId, ContentVersion fileContentVersion, Id BLAId, String driveId){
        system.debug('====inside sendFilesToGD====');
        list<SObject> recordsToUpsert = new list<SObject>();
        if (String.isNotBlank(folderId)) {
            Map<String, String> MapMIMEType = new Map<String, String>{'txt' => 'text/plain', 
                'zip' => 'application/zip','xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'pdf' => 'application/pdf','jpg' => 'image/jpeg','jpeg' => 'image/jpeg','png' => 'image/png',
                'csv' => 'text/csv','pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                'doc' => 'application/msword'};
                    

                    // Convert XML content to base64
            String base64String = EncodingUtil.base64Encode(fileContentVersion.VersionData);
            //String base64String = String.valueOf(fileContentVersion.VersionData);
            String MIMEType = MapMIMEType.get(fileContentVersion.FileExtension);
            // Construct the API request
            String endpoint = 'callout:UDAFGoogleDrive' + '/upload/drive/v3/files?uploadType=multipart&withLink=true' + '&includeItemsFromAllDrives=true&corpora=drive&supportsAllDrives=true&driveId=' + driveId;
            String boundary = '-------------';
            String body = '--' + boundary + '\r\n' +
                'Content-Type: application/json\r\n\r\n' +
                '{"name":"' + fileContentVersion.Title + '","parents":["' + folderId + '"]}\r\n' +
                '--' + boundary + '\r\n' +
                'Content-Transfer-Encoding: base64\r\n' +
                'Content-Type: ' + MIMEType + '\r\n\r\n' +
                base64String + '\r\n' +
                '--' + boundary + '--';
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'multipart/related; boundary="' + boundary + '"');
            request.setBody(body);
            
            // Send the request and get the response
            Http http = new Http();
            HttpResponse resp1 = http.send(request);
            
            //system.debug('resp1.getBody() => ' + resp1.getBody());
            system.debug('resp1.getAllHeaders() => ' + resp1.getHeaderKeys());
            if (resp1.getStatusCode() == 200) {  
                System.debug('65');                  
                String respJSONBody = resp1.getBody();
                Map<String,Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(respJSONBody);
                //system.debug('responseMap => ' + json.serializePretty(responseMap));
                system.debug('==UPLOADED==');
                
                String fileId = (string)responseMap.get('id');
                String fileName = (string)responseMap.get('name');
                system.debug('fileName -> ' + fileName);
                GoogleDrive_Folder__c GDRecordforFile = new GoogleDrive_Folder__c();
                ContentVersion cv = new ContentVersion();
                cv.Id = fileContentVersion.Id;
                cv.FileUpload__c = true;
                GDRecordforFile.isFileUploaded__c = true;
                GDRecordforFile.File_URL__c = 'https://drive.google.com/file/d/' + fileId;
                GDRecordforFile.Name__c = fileName;
                GDRecordforFile.Business_License_Application__c = BLAID;
                //this.filesUploadedToDriveGDRecordList.add(GDRecordforFile);
                //this.contentVersionsToInsert.add(cv);
                //if(!fileName.contains('Signature')){
                  //  this.contentDocsToDeleteId.add(fileContentVersion.ContentDocumentId);    
                //}
                recordsToUpsert.add(cv);
                recordsToUpsert.add(GDRecordforFile);
                
                database.UpsertResult[] result = database.upsert(recordsToUpsert, false);
                for(database.UpsertResult record: result){
                    if(record.isSuccess()){
                        if(record.isCreated()){
                            system.debug('Google Drive Record Created -> ' + record.getId());
                        }else{
                            system.debug('Content Version Record Updated -> ' + record.getId());
                        }
                    }else{
                        system.debug('ERROR ON UPSERT -> ' + record.getErrors());
                    }
                }
                
            } else {
                System.debug('errors==> '+resp1.getBody());
            }
            
        }
    }
    
    public static String getSharedDriveId(String department){
        String driveId = '';
        department = department.toLowerCase();
        system.debug(department);
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:UDAFGoogleDrive' + '/drive/v3/drives');
        request.setMethod('GET');
        system.debug(request);
        Http http = new Http();
        HTTPResponse res = http.send(request);
        system.debug('res**********'+res);
        Map<String, Object> responseMap = (Map<String, Object>)
            JSON.deserializeUntyped(res.getBody());
        system.debug(json.serializePretty(responseMap));
        list<Object> sharedDriveMap = new list<Object>();
        for(String key: responseMap.keySet()){
            system.debug(key);
            system.debug(responseMap.get(key));
            if(key.contains('drive') == true){
                sharedDriveMap = (list<Object>)responseMap.get(key);
            }
        }    
        //system.debug('sharedDriveMap');
        //system.debug(json.serializePretty(sharedDriveMap));
        
        for(Object drive: sharedDriveMap){
            map<String, Object> driveMap = (map<String, Object>)drive;
            String name = (String)driveMap.get('name');
            String id = (String)driveMap.get('id');
            
            if(name.contains('CANNABIS') == true && department.contains('cannabis')){
                system.debug('CANNABIS SHARED DRIVEID FOUND -> ' + id);
                driveId = id;
                //return id;
            }else if(name.contains('ORGANIC') == true && department.contains('organic')){
                system.debug('ORGANIC SHARED DRIVEID FOUND -> ' + id);
                driveId = id;
                //return id;
            }else if(name.contains('HEMP') == true && department.contains('hemp')){
                system.debug('HEMP SHARED DRIVEID FOUND -> ' + id);
                driveId = id;
                //return id;
            }
        }
        return driveId;
    }
    
}
