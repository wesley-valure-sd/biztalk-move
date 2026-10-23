namespace Cloud9.BizTalk.Shared.Components.Archive
{
    using System;
    using System.IO;
    using System.Diagnostics;
    using System.ComponentModel;
    using Microsoft.BizTalk.Message.Interop;
    using Microsoft.BizTalk.Component.Interop;
    using Microsoft.BizTalk.Streaming;


    [ComponentCategory(CategoryTypes.CATID_PipelineComponent)]
    [System.Runtime.InteropServices.Guid("740facec-2bc3-4002-ade6-69ae223ca604")]
    [ComponentCategory(CategoryTypes.CATID_Any)]
    public class Archive : Microsoft.BizTalk.Component.Interop.IComponent, IBaseComponent, IPersistPropertyBag, IComponentUI
    {

        private bool _enabled;

        public bool Enabled
        {
            get
            {
                return _enabled;
            }
            set
            {
                _enabled = value;
            }
        }

        private string _fileMask;

        public string FileMask
        {
            get
            {
                return _fileMask;
            }
            set
            {
                _fileMask = value;
            }
        }

        private string _fileName;

        public string FileName
        {
            get
            {
                return _fileName;
            }
            set
            {
                _fileName = value;
            }
        }

        private string _filePath;

        public string FilePath
        {
            get
            {
                return _filePath;
            }
            set
            {
                _filePath = value;
            }
        }

        private bool _overwrite;

        public bool Overwrite
        {
            get
            {
                return _overwrite;
            }
            set
            {
                _overwrite = value;
            }
        }

        private const string FILE_TRANSPORT_TYPE = "FILE";
        private const string FTP_TRANSPORT_TYPE = "FTP";
        private const string SFTP_TRANSPORT_TYPE = "SFTP";

        #region IBaseComponent members
        /// <summary>
        /// Name of the component
        /// </summary>
        [Browsable(false)]
        public string Name
        {
            get
            {
                return Cloud9.BizTalk.Shared.Components.Archive.Properties.Resources.COMPONENTNAME;
            }
        }

        /// <summary>
        /// Version of the component
        /// </summary>
        [Browsable(false)]
        public string Version
        {
            get
            {
                return Cloud9.BizTalk.Shared.Components.Archive.Properties.Resources.COMPONENTVERSION;
            }
        }

        /// <summary>
        /// Description of the component
        /// </summary>
        [Browsable(false)]
        public string Description
        {
            get
            {
                return Cloud9.BizTalk.Shared.Components.Archive.Properties.Resources.COMPONENTDESCRIPTION;
            }
        }
        #endregion

        #region IPersistPropertyBag members
        /// <summary>
        /// Gets class ID of component for usage from unmanaged code.
        /// </summary>
        /// <param name="classid">
        /// Class ID of the component
        /// </param>
        public void GetClassID(out System.Guid classid)
        {
            classid = new System.Guid("740facec-2bc3-4002-ade6-69ae223ca604");
        }

        /// <summary>
        /// not implemented
        /// </summary>
        public void InitNew()
        {
        }

        /// <summary>
        /// Loads configuration properties for the component
        /// </summary>
        /// <param name="pb">Configuration property bag</param>
        /// <param name="errlog">Error status</param>
        public virtual void Load(Microsoft.BizTalk.Component.Interop.IPropertyBag pb, int errlog)
        {
            object val = null;
            val = this.ReadPropertyBag(pb, "FilePath");
            if ((val != null))
            {
                this._filePath = ((string)(val));
            }
            val = this.ReadPropertyBag(pb, "Enabled");
            if ((val != null))
            {
                this._enabled = ((bool)(val));
            }
            val = this.ReadPropertyBag(pb, "FileMask");
            if ((val != null))
            {
                this._fileMask = ((string)(val));
            }
            val = this.ReadPropertyBag(pb, "FileName");
            if ((val != null))
            {
                this._fileName = ((string)(val));
            }
            val = this.ReadPropertyBag(pb, "Overwrite");
            if ((val != null))
            {
                this._overwrite = ((bool)(val));
            }
        }

        /// <summary>
        /// Saves the current component configuration into the property bag
        /// </summary>
        /// <param name="pb">Configuration property bag</param>
        /// <param name="fClearDirty">not used</param>
        /// <param name="fSaveAllProperties">not used</param>
        public virtual void Save(Microsoft.BizTalk.Component.Interop.IPropertyBag pb, bool fClearDirty, bool fSaveAllProperties)
        {
            this.WritePropertyBag(pb, "FilePath", this.FilePath);
            this.WritePropertyBag(pb, "Enabled", this.Enabled);
            this.WritePropertyBag(pb, "FileMask", this.FileMask);
            this.WritePropertyBag(pb, "FileName", this.FileName);
            this.WritePropertyBag(pb, "Overwrite", this.Overwrite);
        }

        #region utility functionality
        /// <summary>
        /// Reads property value from property bag
        /// </summary>
        /// <param name="pb">Property bag</param>
        /// <param name="propName">Name of property</param>
        /// <returns>Value of the property</returns>
        private object ReadPropertyBag(Microsoft.BizTalk.Component.Interop.IPropertyBag pb, string propName)
        {
            object val = null;
            try
            {
                pb.Read(propName, out val, 0);
            }
            catch (System.ArgumentException)
            {
                return val;
            }
            catch (System.Exception e)
            {
                throw new System.ApplicationException(e.Message);
            }
            return val;
        }

        /// <summary>
        /// Writes property values into a property bag.
        /// </summary>
        /// <param name="pb">Property bag.</param>
        /// <param name="propName">Name of property.</param>
        /// <param name="val">Value of property.</param>
        private void WritePropertyBag(Microsoft.BizTalk.Component.Interop.IPropertyBag pb, string propName, object val)
        {
            try
            {
                pb.Write(propName, ref val);
            }
            catch (System.Exception e)
            {
                throw new System.ApplicationException(e.Message);
            }
        }
        #endregion
        #endregion

        #region IComponentUI members
        /// <summary>
        /// Component icon to use in BizTalk Editor
        /// </summary>
        [Browsable(false)]
        public IntPtr Icon
        {
            get
            {
                return Cloud9.BizTalk.Shared.Components.Archive.Properties.Resources.COMPONENTICON.GetHicon();
            }
        }

        /// <summary>
        /// The Validate method is called by the BizTalk Editor during the build 
        /// of a BizTalk project.
        /// </summary>
        /// <param name="obj">An Object containing the configuration properties.</param>
        /// <returns>The IEnumerator enables the caller to enumerate through a collection of strings containing error messages. These error messages appear as compiler error messages. To report successful property validation, the method should return an empty enumerator.</returns>
        public System.Collections.IEnumerator Validate(object obj)
        {
            // example implementation:
            // ArrayList errorList = new ArrayList();
            // errorList.Add("This is a compiler error");
            // return errorList.GetEnumerator();
            return null;
        }
        #endregion

        #region IComponent members
        /// <summary>
        /// Implements IComponent.Execute method.
        /// </summary>
        /// <param name="pc">Pipeline context</param>
        /// <param name="inmsg">Input message</param>
        /// <returns>Original input message</returns>
        /// <remarks>
        /// IComponent.Execute method is used to initiate
        /// the processing of the message in this pipeline component.
        /// </remarks>
        public IBaseMessage Execute(Microsoft.BizTalk.Component.Interop.IPipelineContext pc, IBaseMessage inmsg)
        {
            Stream originalStrm = null;
            FileStream fileArchive = null;
            BinaryWriter binWriter = null;
            IBaseMessagePart bodyPart = null;
            const int bufferSize = 1024;

            try
            {
                if (Enabled)
                {
                    bodyPart = inmsg.BodyPart;

                    if (bodyPart != null)
                    {
                        string fullPath = string.Empty;
                        string transportType = string.Empty;

                        fullPath = Path.Combine(FilePath, FileName);

                        transportType = inmsg.Context.Read("OutboundTransportType", "http://schemas.microsoft.com/BizTalk/2003/system-properties") as string;

                        if (transportType == null)
                        {
                            transportType = inmsg.Context.Read("InboundTransportType", "http://schemas.microsoft.com/BizTalk/2003/system-properties") as string;
                        }

                        fullPath = ProcessDateTimeMacros(fullPath, inmsg);
                        fullPath = ProcessMessageMacros(fullPath, inmsg);
                        fullPath = ProcessSystemPropertiesMacros(fullPath, transportType, inmsg);

                        // The input macros are handled differently depending upon the communications protocol
                        switch (transportType)
                        {
                            case FILE_TRANSPORT_TYPE:
                                fullPath = ProcessFilePropertiesMacros(fullPath, inmsg);
                                break;
                            case FTP_TRANSPORT_TYPE:
                                fullPath = ProcessFTPPropertiesMacros(fullPath, inmsg);
                                break;
                            case SFTP_TRANSPORT_TYPE:
                                fullPath = ProcessSFTPPropertiesMacros(fullPath, inmsg);
                                break;
                        }

                        if (!Directory.Exists(Path.GetDirectoryName(fullPath)))
                        {
                            Directory.CreateDirectory(Path.GetDirectoryName(fullPath));
                        }

                        if (!Overwrite)
                        {
                            if (File.Exists(fullPath + FileMask))
                            {
                                fullPath = fullPath + "_" + inmsg.MessageID.ToString();
                            }
                        }

                        fullPath = fullPath + FileMask;

                        originalStrm = bodyPart.GetOriginalDataStream();

                        if (!originalStrm.CanSeek)
                        {
                            ReadOnlySeekableStream seekableStream = new ReadOnlySeekableStream(originalStrm);
                            inmsg.BodyPart.Data = seekableStream;
                            originalStrm = inmsg.BodyPart.Data;
                        }

                        pc.ResourceTracker.AddResource(originalStrm);

                        fileArchive = new FileStream(fullPath, FileMode.Create, FileAccess.Write);
                        binWriter = new BinaryWriter(fileArchive);
                        byte[] buffer = new byte[bufferSize];
                        int sizeRead = 0;

                        while ((sizeRead = originalStrm.Read(buffer, 0, bufferSize)) != 0)
                        {
                            binWriter.Write(buffer, 0, sizeRead);
                        }
                    }
                }
            }

            catch (Exception ex)
            {
                EventLog.WriteEntry(ex.Source, ex.Message + "\n" + ex.StackTrace, EventLogEntryType.Warning);
            }

            finally
            {
                if (binWriter != null)
                {
                    binWriter.Flush();
                    binWriter.Close();
                }

                if (originalStrm != null)
                {
                    originalStrm.Seek(0, SeekOrigin.Begin);
                }
            }
            return inmsg;
        }
        #endregion

        #region Archive Code

        private string ProcessDateTimeMacros(string target, IBaseMessage message)
        {
            string updatedTarget = string.Empty;
            string time = string.Empty;

            updatedTarget = target.Replace("%Date%", DateTime.Now.Year.ToString() + DateTime.Now.Month.ToString() + DateTime.Now.Day.ToString());
            updatedTarget = updatedTarget.Replace("%Day%", DateTime.Now.Day.ToString());
            updatedTarget = updatedTarget.Replace("%Month%", DateTime.Now.Month.ToString());

            time = DateTime.Now.TimeOfDay.ToString().Replace(":", ".");

            updatedTarget = updatedTarget.Replace("%Time%", time);
            updatedTarget = updatedTarget.Replace("%Year%", DateTime.Now.Year.ToString());

            return updatedTarget;
        }

        private string ProcessFilePropertiesMacros(string target, IBaseMessage message)
        {
            string updatedTarget = target;
            string receivedFileName = string.Empty;
            string fileName = string.Empty;
            string fileExtension = string.Empty;

            receivedFileName = message.Context.Read("ReceivedFileName", "http://schemas.microsoft.com/BizTalk/2003/file-properties") as string;

            if (!string.IsNullOrEmpty(receivedFileName))
            {
                int index = 0;
                int index2 = 0;
                int fileNameLength = 0;

                index = receivedFileName.LastIndexOf(".");
                index2 = receivedFileName.LastIndexOf("\\") + 1;
                fileNameLength = index - index2;

                fileName = receivedFileName.Substring(index2, fileNameLength);
                fileExtension = receivedFileName.Substring(index);

                updatedTarget = target.Replace("%FileReceivedFileName%", fileName);
                updatedTarget = updatedTarget.Replace("%FileReceivedFileExtension%", fileExtension);
            }
            return updatedTarget;
        }

        private string ProcessSFTPPropertiesMacros(string target, IBaseMessage message)
        {
            string updatedTarget = target;
            string receivedFileName = string.Empty;
            string fileName = string.Empty;
            string fileExtension = string.Empty;

            receivedFileName = message.Context.Read("ReceivedFileName", "http://schemas.microsoft.com/BizTalk/2012/Adapter/sftp-properties") as string;

            if (!string.IsNullOrEmpty(receivedFileName))
            {
                int index = 0;
                int index2 = 0;
                int fileNameLength = 0;

                index = receivedFileName.LastIndexOf(".");
                index2 = receivedFileName.LastIndexOf("\\") + 1;
                fileNameLength = index - index2;

                fileName = receivedFileName.Substring(index2, fileNameLength);
                fileExtension = receivedFileName.Substring(index);

                updatedTarget = target.Replace("%FileReceivedFileName%", fileName);
                updatedTarget = updatedTarget.Replace("%FileReceivedFileExtension%", fileExtension);
            }
            return updatedTarget;
        }

        private string ProcessFTPPropertiesMacros(string target, IBaseMessage message)
        {
            string updatedTarget = target;
            string receivedFileName = string.Empty;
            string fileName = string.Empty;
            string fileExtension = string.Empty;

            receivedFileName = message.Context.Read("ReceivedFileName", "http://schemas.microsoft.com/BizTalk/2003/ftp-properties") as string;
            if (!string.IsNullOrEmpty(receivedFileName))
            {
                int index = 0;
                int fileNameLength = 0;

                index = receivedFileName.LastIndexOf(".");
                fileExtension = receivedFileName.Substring(index);

                fileNameLength = receivedFileName.Length - fileExtension.Length;
                fileName = receivedFileName.Substring(0, fileNameLength);

                updatedTarget = target.Replace("%FTPReceivedFileName%", fileName);
                updatedTarget = updatedTarget.Replace("%FTPReceivedFileExtension%", fileExtension);
            }
            return updatedTarget;
        }

        private string ProcessMessageMacros(string target, IBaseMessage message)
        {
            string updatedTarget = string.Empty;

            updatedTarget = target.Replace("%BodyPartName%", message.BodyPartName.ToString());
            updatedTarget = updatedTarget.Replace("%MessageID%", message.MessageID.ToString());
            updatedTarget = updatedTarget.Replace("%PartCount%", message.PartCount.ToString());

            return updatedTarget;
        }

        private string ProcessSystemPropertiesMacros(string target, string transportType, IBaseMessage Message)
        {
            string updatedTarget = string.Empty;
            string variable = string.Empty;

            updatedTarget = target.Replace("%TransportType%", transportType);

            variable = Message.Context.Read("InterchangeID", "http://schemas.microsoft.com/BizTalk/2003/system-properties") as string;
            updatedTarget = updatedTarget.Replace("%InterchangeID%", variable);

            variable = Message.Context.Read("InterchangeSequenceNumber", "http://schemas.microsoft.com/BizTalk/2003/system-properties") as string;
            updatedTarget = updatedTarget.Replace("%InterchangeSequenceNumber%", variable);

            variable = Message.Context.Read("ReceivePortName", "http://schemas.microsoft.com/BizTalk/2003/system-properties") as string;
            updatedTarget = updatedTarget.Replace("%ReceivePortName%", variable);

            return updatedTarget;
        }

        #endregion
    }
}
