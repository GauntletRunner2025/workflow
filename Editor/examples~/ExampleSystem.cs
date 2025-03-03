using Newtonsoft.Json.Linq;
using Unity.Collections;
using Unity.Entities;
using UnityEngine;
using System;
using System.Linq;

//Normally components are defined in their own files
public struct King : IComponentData { }
public struct Crown : IComponentData { }
public struct IsAlive : IComponentData { }

public partial class Example : SystemBase
{

        public static string[] ExtractAgents(string jsonContent)
        {
            try
            {
                var jsonObject = JObject.Parse(jsonContent);
                
                if (!jsonObject.ContainsKey("agents"))
                {
                    throw new Exception("JSON does not contain 'agents' array");
                }
                
                return jsonObject["agents"].ToObject<string[]>();
            }
            catch (Exception ex)
            {
                if (ex.Message == "JSON does not contain 'agents' array")
                {
                    throw;
                }
                throw new Exception("Failed to parse JSON: " + ex.Message);
            }
        }
    protected override void OnCreate()
    {
        //This function happens once no matter what

        //Only bother updating if there are kings to crown
        //This is usually not necessary, but useful for making assumptions about Singletons existing
        RequireForUpdate<King>();

        //Systems are auto-created and enabled by default, but you could also turn it off
        this.Enabled = true;
    }

    protected override void OnStartRunning()
    {
        //This runs whenever a system about to update after having been newly enabled or re-enabled
    }

    //An internal flag we can use to keep track of what we've already looked at or worked on
    struct Flag : IComponentData { }

    protected override void OnUpdate()
    {
        using EntityCommandBuffer ecb = new EntityCommandBuffer(Allocator.TempJob);
        foreach (var (item, entity) in SystemAPI
            .Query<King>()
            .WithAll<IsAlive>()
            .WithNone<Crown>()
            .WithEntityAccess())
        {

            ecb.AddComponent(entity, new Crown());
        }

        ecb.Playback(EntityManager);
    }
}