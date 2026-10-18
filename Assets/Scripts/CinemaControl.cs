using UnityEngine;
using UnityEngine.InputSystem;

public class CinemaControl : MonoBehaviour
{
    [Header("Target")]
    public GameObject target;

    [Header("Rotation")]
    public float rotateSpeed = 60.0f;   // 最大旋转速度
    public float smoothTime = 0.15f;    // 加速/减速平滑时间

    private float currentSpeed = 0.0f;
    private float speedVelocity = 0.0f;

    private void Update()
    {
        if (target == null)
            return;

        float input = 0.0f;

        // 新版 Input System
        if (Keyboard.current != null)
        {
            if (Keyboard.current.aKey.isPressed)
            {
                input = -1.0f;
            }

            if (Keyboard.current.dKey.isPressed)
            {
                input = 1.0f;
            }
        }

        // 目标旋转速度
        float targetSpeed = input * rotateSpeed;

        // 平滑加速 / 减速
        currentSpeed = Mathf.SmoothDamp(
            currentSpeed,
            targetSpeed,
            ref speedVelocity,
            smoothTime
        );

        // 绕目标旋转
        RotateAround(
            target.transform.position,
            Vector3.up,
            currentSpeed * Time.deltaTime
        );
    }

    private void RotateAround(Vector3 center, Vector3 axis, float angle)
    {
        Quaternion rotation = Quaternion.AngleAxis(angle, axis);

        Vector3 beforeVector = transform.position - center;
        Vector3 afterVector = rotation * beforeVector;

        transform.position = afterVector + center;

        // 相机始终看向目标
        transform.LookAt(center);
    }
}