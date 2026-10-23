namespace Cloud9.BizTalk.PipelineComponent.EmdeonPayload
{
    using System;
    using System.IO;
    using System.Diagnostics;
    using System.ComponentModel;
    using Microsoft.BizTalk.Message.Interop;
    using Microsoft.BizTalk.Component.Interop;
    using Microsoft.BizTalk.Streaming;


    [ComponentCategory(CategoryTypes.CATID_PipelineComponent)]
    [System.Runtime.InteropServices.Guid("B812D33E-5164-4C5A-B841-05495F93A8BA")]
    [ComponentCategory(CategoryTypes.CATID_Any)]
    public class EmdeonPayload : Microsoft.BizTalk.Component.Interop.IComponent, IBaseComponent, IPersistPropertyBag, IComponentUI
    {
        #region IBaseComponent members
        /// <summary>
        /// Name of the component
        /// </summary>
        [Browsable(false)]
        public string Name
        {
            get
            {
                return Cloud9.BizTalk.PipelineComponent.EmdeonPayload.Properties.Resources.COMPONENTNAME;
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
                return Cloud9.BizTalk.PipelineComponent.EmdeonPayload.Properties.Resources.COMPONENTVERSION;
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
                return Cloud9.BizTalk.PipelineComponent.EmdeonPayload.Properties.Resources.COMPONENTDESCRIPTION;
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
            classid = new System.Guid("B812D33E-5164-4C5A-B841-05495F93A8BA");
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
        }

        /// <summary>
        /// Saves the current component configuration into the property bag
        /// </summary>
        /// <param name="pb">Configuration property bag</param>
        /// <param name="fClearDirty">not used</param>
        /// <param name="fSaveAllProperties">not used</param>
        public virtual void Save(Microsoft.BizTalk.Component.Interop.IPropertyBag pb, bool fClearDirty, bool fSaveAllProperties)
        {
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
                return Cloud9.BizTalk.PipelineComponent.EmdeonPayload.Properties.Resources.COMPONENTICON.GetHicon();
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
                    String originalPayload = "";

                    if (!originalStrm.CanSeek)
                    {
                        ReadOnlySeekableStream seekableStream = new ReadOnlySeekableStream(originalStrm);
                        inmsg.BodyPart.Data = seekableStream;
                    }

                    originalStrm = inmsg.BodyPart.Data;
                    originalPayload = new StreamReader(originalStrm).ReadToEnd();
                    byte [] payLoadbytes = System.Text.Encoding.ASCII.GetBytes(originalPayload);
                    
                    string length = payLoadbytes.Length.ToString();
                    string base64 = Convert.ToBase64String(payLoadbytes);

                    // The msg_envelope is set as a message context property from the 
                    // orchestration sending the message through send ports using pipelines using this component so they can be replaced dynamicially here. 
                    string emdeonPayload = (string)inmsg.Context.Read( "msg_envelope", "https://Cloud9.BizTalk.X12.Schemas.CHCEmdeonPropertySchema");

                    // file_data and file_size are expected to be included in the msg_envelope and are set exclusively based on the 
                    // message payload.
                    emdeonPayload = emdeonPayload.Replace( "<value_file_data>", base64);
                    emdeonPayload = emdeonPayload.Replace("<value_file_size>", length);

                    // This replaces the original payload with the newly wrapped message
                    System.IO.MemoryStream m = new System.IO.MemoryStream();
                    System.IO.StreamWriter writer = new System.IO.StreamWriter(m);
                    writer.AutoFlush = true;
                    writer.Write(emdeonPayload);
                    m.Position = 0;
                    inmsg.BodyPart.Data = m;

                    pc.ResourceTracker.AddResource(originalStrm);
                }
            }

            catch (Exception ex)
            {
                EventLog.WriteEntry("Application", ex.Message + "\n" + ex.StackTrace, EventLogEntryType.Error);
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

        #region EmdeonPayload Code


        #endregion
    }
}
