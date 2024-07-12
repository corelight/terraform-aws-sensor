import os

TEST_DIR = os.path.dirname(f"{os.path.abspath(__file__)}")
PROJECT_DIR = os.path.abspath(os.path.join(TEST_DIR, os.curdir))
test_data_dir = os.path.join(PROJECT_DIR, "test_data")
