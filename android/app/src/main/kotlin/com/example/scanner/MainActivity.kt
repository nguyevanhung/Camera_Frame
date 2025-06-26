package com.example.scanner  // Make sure this matches your actual package name

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.ByteArrayOutputStream

// class main : FlutterActivity() {
//     // This is the main entry point for the Flutter application
//     private val CHANNEL = "frameit/detect_corners"
    
// }


class MainActivity : FlutterActivity() {
    private val CHANNEL = "frameit/detect_corners"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Init OpenCV
        if (!OpenCVLoader.initDebug()) {
            println("OpenCV failed to init")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "cropImage" -> {
                    val path = call.argument<String>("path")!!
                    val points = call.argument<List<Map<String, Int>>>("points")!!
                    val croppedBytes = cropImage(path, points)
                    result.success(croppedBytes)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun cropImage(path: String, points: List<Map<String, Int>>): ByteArray? {
        val bitmap = BitmapFactory.decodeFile(path)
        val src = Mat()
        Utils.bitmapToMat(bitmap, src)

        val srcPts = MatOfPoint2f(*points.map {
            Point(it["x"]!!.toDouble(), it["y"]!!.toDouble())
        }.toTypedArray())

        // Tính chiều rộng và cao mới dựa trên khoảng cách 2 cạnh
        val widthTop = distance(points[0], points[1])
        val widthBottom = distance(points[2], points[3])
        val dstWidth = maxOf(widthTop, widthBottom)

        val heightLeft = distance(points[0], points[3])
        val heightRight = distance(points[1], points[2])
        val dstHeight = maxOf(heightLeft, heightRight)

        val dstPts = MatOfPoint2f(
            Point(0.0, 0.0),
            Point(dstWidth, 0.0),
            Point(dstWidth, dstHeight),
            Point(0.0, dstHeight)
        )

        val transform = Imgproc.getPerspectiveTransform(srcPts, dstPts)
        val output = Mat()
        Imgproc.warpPerspective(src, output, transform, Size(dstWidth, dstHeight))

        val outBitmap = Bitmap.createBitmap(dstWidth.toInt(), dstHeight.toInt(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(output, outBitmap)

        val stream = ByteArrayOutputStream()
        outBitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)
        return stream.toByteArray()
    }

    private fun distance(p1: Map<String, Int>, p2: Map<String, Int>): Double {
        val dx = (p1["x"]!! - p2["x"]!!).toDouble()
        val dy = (p1["y"]!! - p2["y"]!!).toDouble()
        return Math.sqrt(dx * dx + dy * dy)
    }
}