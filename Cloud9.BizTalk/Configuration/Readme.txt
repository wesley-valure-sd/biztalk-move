The PartyCollection.xml file contains the Party bindings from the BizTalk lab environment. It should only be created from the BizTalk lab server.

Any party or agreement changes should be applied manually to the lab, exported, and overwritten in the PartyCollection.xml file.

PartyCollection.xml will will be manually imported as necessary.

Any ISA03/ISA04 values do not get exported with party bindings. These values must be manually applied after party bindings have been imported. At this time, CLOUD9_ChangeHealthCareHTTP is the only agreement to which this applies.


****Manual Deployment Steps****
The following must be set manually after importing the PartyCollection.xml file into BizTalk.

Agreement: Cloud9_ChangeHealthCareHTTP
ChangeHealthcare->Cloud9 Tab
	- Identifiers section
	- Security qualifier (ISA3): 01
	- Security value (ISA4): P62TX59AL