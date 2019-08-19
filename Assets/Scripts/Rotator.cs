using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotator : MonoBehaviour
{
    [SerializeField]
    private float _speed = 0.1f;

    private void Update()
    {
        transform.Rotate(Vector3.one * _speed);
    }
}
