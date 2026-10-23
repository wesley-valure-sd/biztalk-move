namespace Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings
{
    using System;
    using System.IO;
    using System.Diagnostics;
    using System.ComponentModel;
    using Microsoft.BizTalk.Message.Interop;
    using Microsoft.BizTalk.Component.Interop;
    using Microsoft.BizTalk.Streaming;


    [ComponentCategory(CategoryTypes.CATID_PipelineComponent)]
    [System.Runtime.InteropServices.Guid("8B36EE67-3EF3-4157-977B-D17141ECD961")]
    [ComponentCategory(CategoryTypes.CATID_Any)]
    public class ReplacePayloadStrings : Microsoft.BizTalk.Component.Interop.IComponent, IBaseComponent, IPersistPropertyBag, IComponentUI
    {
        private string _replacementKeySSOAppName;

        public string ReplacementKeySSOAppName
        {
            get
            {
                return _replacementKeySSOAppName;
            }
            set
            {
                _replacementKeySSOAppName = value;
            }
        }

        private string _replacementKeySSOKeyName;

        public string ReplacementKeySSOKeyName
        {
            get
            {
                return _replacementKeySSOKeyName;
            }
            set
            {
                _replacementKeySSOKeyName = value;
            }
        }

        #region IBaseComponent members
        /// <summary>
        /// Name of the component
        /// </summary>
        [Browsable(false)]
        public string Name
        {
            get
            {
                return Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings.Properties.Resources.COMPONENTNAME;
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
                return Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings.Properties.Resources.COMPONENTVERSION;
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
                return Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings.Properties.Resources.COMPONENTDESCRIPTION;
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
            classid = new System.Guid("8B36EE67-3EF3-4157-977B-D17141ECD961");
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
            var val = this.ReadPropertyBag(pb, "ReplacementKeySSOAppName");
            if ((val != null))
            {
                this._replacementKeySSOAppName = ((string)(val));
            }

            val = this.ReadPropertyBag(pb, "ReplacementKeySSOKeyName");
            if ((val != null))
            {
                this._replacementKeySSOKeyName = ((string)(val));
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
            this.WritePropertyBag(pb, "ReplacementKeySSOAppName", this.ReplacementKeySSOAppName);
            this.WritePropertyBag(pb, "ReplacementKeySSOKeyName", this.ReplacementKeySSOKeyName);
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
                return Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings.Properties.Resources.COMPONENTICON.GetHicon();
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
            IBaseMessagePart bodyPart = null;

            try
            {
                bodyPart = inmsg.BodyPart;

                if (bodyPart != null)
                {
                    originalStrm = bodyPart.GetOriginalDataStream();
                    String newString = "";

                    if (!originalStrm.CanSeek)
                    {
                        ReadOnlySeekableStream seekableStream = new ReadOnlySeekableStream(originalStrm);
                        inmsg.BodyPart.Data = seekableStream;
                    }

                    originalStrm = inmsg.BodyPart.Data;
                    newString = new StreamReader(originalStrm).ReadToEnd();

                    string replacementPattern = SSOSettingsFileReader.ReadString(ReplacementKeySSOAppName, ReplacementKeySSOKeyName);

                    // Format of pattern should be : key1=value1,key2=value2,key3=value3,key4=value4...
                    // commas and equal sign should not be part of the key or replacement value.
                    foreach (var replaceEl in replacementPattern.Split(','))
                    {
                        var replaceMapping = replaceEl.Split('=');

                        // This is strictly a configuration error and will not result in critical downstream failure, so 
                        // log it and continue
                        if (replaceMapping.Length != 2)
                        {
                            EventLog.WriteEntry("Application", System.String.Format("Error parsing replacement string({0}). Format should be <key>=<value>.", replaceEl), EventLogEntryType.Warning);
                        }
                        else
                        {
                            string fromStr = replaceMapping[0];
                            string toStr = replaceMapping[1];

                            newString = newString.Replace(fromStr, toStr);
                        }
                    }

                    System.IO.MemoryStream m = new System.IO.MemoryStream();
                    System.IO.StreamWriter writer = new System.IO.StreamWriter(m);
                    writer.AutoFlush = true;
                    writer.Write(newString);
                    m.Position = 0;
                    inmsg.BodyPart.Data = m;

                    pc.ResourceTracker.AddResource(originalStrm);
                }
            }

            catch (Exception ex)
            {
                EventLog.WriteEntry(ex.Source, ex.Message + "\n" + ex.StackTrace, EventLogEntryType.Warning);
            }

            finally
            {
                if (originalStrm != null)
                {
                    originalStrm.Seek(0, SeekOrigin.Begin);
                }
            }

            return inmsg;
        }
        #endregion

        #region ReplacePayloadStrings Code


        #endregion
    }
}
