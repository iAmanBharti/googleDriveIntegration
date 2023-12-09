/*
Class Name- updateFileName
Description- Rename file after file upload on Omniscript
Developed By- Akshay Lohar
Developed On - 01-Feb-2023
*/
global with sharing class updateFileName implements Callable{
    
   public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
		 Map<String, Object> output = (Map<String, Object>)args.get('output');
		 Map<String, Object> options = (Map<String, Object>)args.get('options');
        
        return invokeMethod(action, input, output, options);

    }
    
     private Object invokeMethod(String methodName, Map<String, Object> 
      input, Map<String, Object> output, Map<String, Object> options){
            Boolean result = true; 
          	
            if(methodName.endsWithIgnoreCase('changeFileName')){
                changeFileName(input,output,options);
            }else
            {
                result = false;
            }
            
       
        return result;
    }
    
     public void changeFileName(map<string,object> input,map<string,object> output,map<string,object>options){
         try{
             String fileControlName = (String)input.get('fileControlName');
             String FileName = (String)input.get('fileName');
        
             object[] fileObj =(object[]) input.get(fileControlName);
             List<ContentVersion> listContentVersion = new List<ContentVersion>();
             for(integer i=0;i<fileObj.size();i++)
             {
                 Map<String, Object> obj=(Map<String, Object>)fileObj[i];
                 String ContentDocId =(String) obj.get('data');
                 System.debug('ContentDocId'+ContentDocId);
                 ContentVersion contentVersion = [SELECT Id, FileExtension,FileType, Title FROM ContentVersion where ContentDocumentId =: ContentDocId limit 1];
                                      
                 if(i == 0)
                  {
                       contentVersion.Title = FileName;
                  }
                 else
                 {
                     contentVersion.Title = FileName + ' '+i; 
                 }
                 
                 listContentVersion.add(contentVersion);
             }
             if(listContentVersion.size() > 0)
             {
                 update listContentVersion;
             }
     
         }  catch(Exception e){
           System.debug('Exception'+e.getMessage());
        }       
         
     }
}
