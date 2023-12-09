# googleDriveIntegration
https://help.salesforce.com/s/articleView?id=sf.admin_files_connect_google_auth.htm&type=5

=> Create a Project in the Google Developers Console

	-> In the OAuth Consent Screen tab, enter a valid email address and application name

	->	Copy the client ID and client secret values ---- 
	
=>	Create an Authentication Provider in Salesforce

	->	Consumer Key 	— Enter the client ID you copied when creating the Google project.
	->	Consumer Secret — Enter the client secret you copied when creating the Google project.
	
	->	Click Save. Then, at the bottom of the Auth. Provider detail page, copy the Callback URL entry to a text file. (Use this URL when editing the Google project.)
	
=>	Edit the Project in the Google Developer Console

	->	In the Authorized Redirect URIs section, add the Callback URL you copied when creating the authentication provider in Salesforce, and click Save.
	
	
	
