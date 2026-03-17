from app_web import app

def test_index():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200

def test_start_load():
    client = app.test_client()
    response = client.post('/start', json={"duration": 1, "cores": 1})
    assert response.status_code == 200
    data = response.get_json()
    assert "status" in data