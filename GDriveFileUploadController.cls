public class GDriveFileUploadController implements Queueable, Database.AllowsCallouts  {
    
    public list<id> contentDocId=new list<id>();
    public list<id> BLAId=new list<id>();
    public string folderId;
    public map<string,string>mapfileandFolderId = new map<string,string>();
    
    public GDriveFileUploadController(list<id> contentDocumentIds,map<string,string>mapfileandFolderIds,list<id> BLAIds ) {
        
        contentDocId = contentDocumentIds;
        mapfileandFolderId = mapfileandFolderIds; 
        BLAId = BLAIds;
        system.debug('INisde file uploader construction');
        
    }
    
    public void execute(QueueableContext context) {
        system.debug('Inisde execute method ');
        Map<String, List<String>> folderIDTOFileURLMap = new map<String, List<String>>(); //This map stores Folder ID and its respective list of files
        try{
            
            system.debug('Inisde GDriveFileUploadController ');
            system.debug('mapfileandFolderId'+mapfileandFolderId);
            system.debug('--contentDocId---'+contentDocId);
            
            List<ContentVersion> lstContestVer = [SELECT Id, VersionData, FileExtension,FileType, Title FROM ContentVersion where ContentDocumentId IN: contentDocId];
            system.debug('------lstContestVer---'+lstContestVer);
            
            for(ContentVersion objCV : lstContestVer){
                string fileTitle ='';
                system.debug('---mapfileandFolderId queable -'+mapfileandFolderId);
                folderId ='';
                string applicationName = 'Application And Narrative';
                if (objCV.Title.contains('Application')) {
                    fileTitle = objCV.Title;
                    folderId= mapfileandFolderId.get('Application And Narrative');
                    system.debug('folder id is application'+folderId);
                }
                else if (objCV.Title.contains('Map') ||objCV.Title.contains('Histories') ){
                    fileTitle = objCV.Title;
                    folderId= mapfileandFolderId.get('Histories And Maps');
                    system.debug('folder id is histories'+folderId);
                    
                }else {
                    system.debug('--else part--'+objCV.Title);
                    system.debug('-------'+mapfileandFolderId.get(objCV.Title));
                    if(mapfileandFolderId.containsKey(objCV.Title)){
                        folderId= mapfileandFolderId.get(objCV.Title);
                    }
                    else{
                        system.debug(' else objCV.Title---'+objCV.Title);
                        fileTitle = objCV.Title;
                        system.debug('fileTitle--- line 50'+mapfileandFolderId);
                        folderId= mapfileandFolderId.get('Default');
                        system.debug('folder id for other'+folderId);
                    }
                }
                
                if (String.isNotBlank(folderId)) {
                    system.debug('File Name before send'+fileTitle);
                    system.debug('folderIde before send'+folderId);
                    Map<String, String> MapMIMEType = new Map<String, String>{'pdf' => 'application/pdf', 'txt' => 'text/plain', 
                        'zip' => 'application/zip','xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'pdf' => 'application/pdf','jpg' => 'image/jpeg','jpeg' => 'image/jpeg','png' => 'image/png',
                        'csv' => 'text/csv','pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation'};
                            String boundary = '----------';
                    String delimiter = '\r\n--' + boundary + '\r\n';
                    String close_delim = '\r\n--' + boundary + '--';       
                    
                    String base64String = EncodingUtil.base64Encode(objCV.VersionData);
                    String gdriveFolderId= folderId;
                    String MIMEType = MapMIMEType.get(objCV.FileExtension);     
                    String body = delimiter + 'Content-Type: application/json\r\n\r\n' + '{ "title" : "' + objCV.Title + '",' + ' "mimeType" : "' + MIMEType + '",' + '"parents":[{"id":"'+ gdriveFolderId +'"}]}' + delimiter + 'Content-Type:  "' + MIMEType + '"\r\n' + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + base64String + close_delim;
                    
                    // try{
                    Http http = new Http();
                    HttpRequest req1 = new HttpRequest();
                    String UploadURL='/upload/drive/v2/files?uploadType=multipart&withLink=true';
                    req1.setEndpoint('callout:NameCredUda' + UploadURL);
                    req1.setHeader('Content-Type', 'multipart/mixed; boundary="' + boundary + '"');
                    req1.setHeader('Content-length', String.valueOf(body.length()));
                    req1.setBody(body);
                    req1.setMethod('POST');
                    HttpResponse resp1 = http.send(req1);
                    if (resp1.getStatusCode() == 200) {
                        System.debug('File uploaded successfully');
                        
                        String fileURL = '';	
                        
                        List<String> fileURLList = new List<String>();
                        
                        /*if(folderIDTOFileURLMap.containsKey(folderID)){
                            fileURLList = folderIDTOFileURLMap.get(folderId);
                            fileURLList.add(fileURL);
                            folderIDTOFileURLMap.put(folderId, fileURLList);                            
                        }else{
                            fileURLList.add(fileURL);
                            folderIDTOFileURLMap.put(folderId, fileURLList);
                        }*/
                    }
                    
                }
            }
            /*if(folderIDTOFileURLMap.size()> 0){
                updateFileURLOnGoogleDriveRecord(folderIDTOFileURLMap);
            }*/
        }
        catch(Exception e){
            system.debug('Inisde catch block '+e);
            GenericLogs.logException(e);
        }
    }
    
    /*public void updateFileURLOnGoogleDriveRecord(Map<String, List<String>> folderIdfileURLmap){
        Set<String> folderIds = folderIdfileURLmap.keySet();
        List<GoogleDrive_Folder__c> gDriveFolderToUpdate = [SELECT Id, File_URL__c, FolderId__c FROM GoogleDrive_Folder__c WHERE FolderId__c IN :folderIds];
        
        for(GoogleDrive_Folder__c gdf: gDriveFolderToUpdate){
            gdf.File_URL__c = folderIdfileURLmap.get(gdf.FolderId__c)[0];
        }
        
        update gDriveFolderToUpdate;
    }*/
}
