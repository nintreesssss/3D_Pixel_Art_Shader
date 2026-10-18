using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class DrawLeaf : MonoBehaviour
{
    public Mesh ShapeMesh; // 树冠分布模型
    public Mesh LeafMesh;  // 树叶面片
    public List<Material> mats = new List<Material>();

    [Range(0f, 2f)]
    public float LeafDensity = 1f;

    [Range(0.1f, 4f)]
    public float LeafSize = 1f;

    [Range(0f, 2f)]
    public float LeafOffset = 0f;

    private List<LeafData> leafDatas;

    private void Start()
    {
        InitLeaf();
    }

    private void InitLeaf()
    {
        leafDatas = new List<LeafData>();

        if (ShapeMesh == null)
        {
            Debug.LogError("没有设置 ShapeMesh。", this);
            return;
        }

        if (LeafMesh == null)
        {
            Debug.LogError("没有设置 LeafMesh。", this);
            return;
        }

        if (mats == null || mats.Count == 0)
        {
            Debug.LogError("没有设置树叶材质。", this);
            return;
        }

        Vector3[] vertices = ShapeMesh.vertices;
        Vector3[] normals = ShapeMesh.normals;

        if (vertices.Length != normals.Length)
        {
            Debug.LogError("ShapeMesh 没有正确的顶点法线。", this);
            return;
        }

        for (int i = 0; i < vertices.Length; i++)
        {
            if (Random.value > LeafDensity)
                continue;

            LeafData data = new LeafData
            {
                localPos = vertices[i],
                localNormal = normals[i].normalized,
                size = Random.Range(0.5f, 1f),
                matIndex = Random.Range(0, mats.Count)
            };

            leafDatas.Add(data);
        }
    }

    private void Update()
    {
        DrawLeafs();
    }

    private void DrawLeafs()
    {
        if (leafDatas == null || leafDatas.Count == 0)
            return;

        List<List<Matrix4x4>> matrices =
            new List<List<Matrix4x4>>();

        List<List<Vector4>> normals =
            new List<List<Vector4>>();

        for (int i = 0; i < mats.Count; i++)
        {
            matrices.Add(new List<Matrix4x4>(1023));
            normals.Add(new List<Vector4>(1023));
        }

        foreach (LeafData data in leafDatas)
        {
            int index = data.matIndex;

            Vector3 worldNormal =
                transform.TransformDirection(
                    data.localNormal
                ).normalized;

            Vector3 worldPos =
                transform.TransformPoint(
                    data.localPos
                );

            worldPos += worldNormal * LeafOffset;

            Vector3 scale =
                Vector3.one * data.size * LeafSize;

            // 旋转保持 identity，由 Shader 完成 Billboard
            Matrix4x4 matrix = Matrix4x4.TRS(
                worldPos,
                Quaternion.identity,
                scale
            );

            matrices[index].Add(matrix);

            normals[index].Add(
                new Vector4(
                    worldNormal.x,
                    worldNormal.y,
                    worldNormal.z,
                    0f
                )
            );

            if (matrices[index].Count >= 1023)
            {
                DrawBatch(
                    index,
                    matrices[index],
                    normals[index]
                );

                matrices[index].Clear();
                normals[index].Clear();
            }
        }

        for (int i = 0; i < mats.Count; i++)
        {
            if (matrices[i].Count == 0)
                continue;

            DrawBatch(
                i,
                matrices[i],
                normals[i]
            );
        }
    }

    private void DrawBatch(
        int materialIndex,
        List<Matrix4x4> matrices,
        List<Vector4> normals)
    {
        Material material = mats[materialIndex];

        if (material == null)
            return;

        MaterialPropertyBlock block =
            new MaterialPropertyBlock();

        block.SetVectorArray(
            "_Normal",
            normals
        );

        Graphics.DrawMeshInstanced(
            LeafMesh,
            0,
            material,
            matrices,
            block,
            ShadowCastingMode.Off,
            false,
            gameObject.layer
        );
    }

    public struct LeafData
    {
        public Vector3 localPos;
        public Vector3 localNormal;
        public float size;
        public int matIndex;
    }
}