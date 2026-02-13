async function testCount() {
  const baseUrl = 'http://localhost:3080/api/v1';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiMWU4NmY2MGMtYzk2OC00OGFmLThkYjYtN2IwMTA1OWZjZWY4IiwicGhvbmUiOiIrOTkzNjE5OTk5OTkiLCJpYXQiOjE3NzA5MTc0NDEsImV4cCI6MTc3MDkxODM0MX0.7WQOhW-KdWj85-cs67bzGt_MX-8Ttji4z_vIIlWu1oE'; 

  console.log('Testing GET /posts/count with token...');
  try {
    const res = await fetch(`${baseUrl}/posts/count`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Status:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('Data:', data);
    } else {
      console.log('Text:', await res.text());
    }
  } catch (error) {
    console.error('Error with token:', error.message);
  }

  console.log('\nTesting GET /posts/count WITHOUT token...');
  try {
    const res = await fetch(`${baseUrl}/posts/count`);
    console.log('Status:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('Data:', data);
    } else {
      console.log('Text:', await res.text());
    }
  } catch (error) {
    console.error('Error without token:', error.message);
  }
}

testCount();
