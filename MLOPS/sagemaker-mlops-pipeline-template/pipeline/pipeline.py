from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import ProcessingStep, TrainingStep
from sagemaker.workflow.step_collections import RegisterModel
from sagemaker.sklearn.processing import SKLearnProcessor
from sagemaker.sklearn.estimator import SKLearn
from sagemaker.workflow.parameters import ParameterString
from sagemaker.workflow.pipeline_context import PipelineSession
from sagemaker.model_metrics import MetricsSource, ModelMetrics
import boto3
import sagemaker
import os

region = boto3.Session().region_name
role = sagemaker.get_execution_role()
sagemaker_session = PipelineSession()

input_data = ParameterString(name="InputData", default_value="s3://your-bucket/dataset.csv")

processor = SKLearnProcessor(
    framework_version="0.23-1",
    role=role,
    instance_type="ml.m5.xlarge",
    instance_count=1,
    base_job_name="preprocessing",
    sagemaker_session=sagemaker_session
)

step_process = ProcessingStep(
    name="Preprocess",
    processor=processor,
    inputs=[
        sagemaker.processing.ProcessingInput(source=input_data, destination="/opt/ml/processing/input")
    ],
    outputs=[
        sagemaker.processing.ProcessingOutput(output_name="train", source="/opt/ml/processing/train"),
        sagemaker.processing.ProcessingOutput(output_name="test", source="/opt/ml/processing/test")
    ],
    code="src/preprocessing.py",
    job_arguments=[
        "/opt/ml/processing/input/iris.csv",
        "/opt/ml/processing/train/train.csv",
        "/opt/ml/processing/test/test.csv"
    ]
)

estimator = SKLearn(
    entry_point="train.py",
    source_dir="src",
    role=role,
    instance_type="ml.m5.large",
    framework_version="0.23-1",
    sagemaker_session=sagemaker_session
)

step_train = TrainingStep(
    name="TrainModel",
    estimator=estimator,
    inputs={
        "train": step_process.properties.ProcessingOutputConfig.Outputs["train"].S3Output.S3Uri
    }
)

model_metrics = ModelMetrics(
    model_statistics=MetricsSource(
        s3_uri="s3://your-bucket/eval.json",
        content_type="application/json"
    )
)

step_register = RegisterModel(
    name="RegisterModel",
    estimator=estimator,
    model_data=step_train.properties.ModelArtifacts.S3ModelArtifacts,
    content_types=["text/csv"],
    response_types=["text/csv"],
    inference_instances=["ml.m5.large"],
    model_package_group_name="MyModelGroup",
    model_metrics=model_metrics,
    sagemaker_session=sagemaker_session
)

pipeline = Pipeline(
    name="MLOpsPipeline",
    parameters=[input_data],
    steps=[step_process, step_train, step_register],
    sagemaker_session=sagemaker_session
)

if __name__ == '__main__':
    pipeline.upsert()
    execution = pipeline.start()
